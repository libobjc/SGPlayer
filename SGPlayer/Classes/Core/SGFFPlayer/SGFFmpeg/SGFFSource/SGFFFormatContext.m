//
//  SGFFFormatContext.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFFormatContext.h"
#import "SGFFError.h"
#import "avformat.h"

static int formatContextInterruptCallback(void * ctx)
{
    SGFFFormatContext * obj = (__bridge SGFFFormatContext *)ctx;
    switch (obj.state)
    {
        case SGFFSourceStateClosed:
        case SGFFSourceStateFailed:
            return YES;
        default:
            return NO;
    }
}

@interface SGFFFormatContext ()

{
    AVFormatContext * _formatContext;
}

@property (nonatomic, assign) SGFFSourceState state;

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, weak) id <SGFFSourceDelegate> delegate;

@property (nonatomic, copy) NSError * error;
@property (nonatomic, strong) NSArray <SGFFStream *> * streams;

@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSInvocationOperation * openOperation;
@property (nonatomic, strong) NSInvocationOperation * readOperation;

@end

@implementation SGFFFormatContext

- (instancetype)initWithContentURL:(NSURL *)contentURL delegate:(id <SGFFSourceDelegate>)delegate
{
    if (self = [super init])
    {
        self.contentURL = contentURL;
        self.delegate = delegate;
    }
    return self;
}

- (void)open
{
    self.state = SGFFSourceStateOpening;
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 2;
    self.operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    
    self.openOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(openThread) object:nil];
    self.openOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.openOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.operationQueue addOperation:self.openOperation];
}

- (void)read
{
    self.state = SGFFSourceStateReading;
    
    self.readOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(readThread) object:nil];
    self.readOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.readOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.readOperation addDependency:self.openOperation];
    [self.operationQueue addOperation:self.readOperation];
}

- (void)close
{
    self.state = SGFFSourceStateClosed;
    [self.operationQueue cancelAllOperations];
    [self.operationQueue waitUntilAllOperationsAreFinished];
    if (_formatContext)
    {
        avformat_close_input(&_formatContext);
        _formatContext = NULL;
    }
}


#pragma mark - Thread

- (void)openThread
{
    _formatContext = avformat_alloc_context();
    
    if (!_formatContext)
    {
        self.error = SGFFCreateErrorCode(SGFFErrorCodeFormatCreate);
        [self callbackForError];
        return;
    }
    
    _formatContext->interrupt_callback.callback = formatContextInterruptCallback;
    _formatContext->interrupt_callback.opaque = (__bridge void *)self;
    
    NSString * contentURLString = self.contentURL.absoluteString;
    int reslut = avformat_open_input(&_formatContext, contentURLString.UTF8String, NULL, NULL);
    self.error = SGFFGetErrorCode(reslut, SGFFErrorCodeFormatOpenInput);
    if (self.error)
    {
        if (_formatContext) {
            avformat_free_context(_formatContext);
        }
        [self callbackForError];
        return;
    }
    
    reslut = avformat_find_stream_info(_formatContext, NULL);
    self.error = SGFFGetErrorCode(reslut, SGFFErrorCodeFormatFindStreamInfo);
    if (self.error)
    {
        if (_formatContext) {
            avformat_close_input(&_formatContext);
            avformat_free_context(_formatContext);
        }
        [self callbackForError];
        return;
    }
    
    NSMutableArray <SGFFStream *> * streams = [NSMutableArray array];
    for (int i = 0; i < _formatContext->nb_streams; i++)
    {
        SGFFStream * stream = [[SGFFStream alloc] init];
        stream.index = i;
        stream.stream = _formatContext->streams[i];
        [streams addObject:stream];
    }
    self.streams = [streams copy];
    
    [self callbackForOpened];
}

- (void)readThread
{
    AVPacket packet;
    while (YES)
    {
        BOOL shouldBreak = NO;
        switch (self.state)
        {
            case SGFFSourceStateReadFinished:
            case SGFFSourceStateClosed:
            case SGFFSourceStateFailed:
                shouldBreak = YES;
                break;
            default:
                break;
        }
        if (shouldBreak)
        {
            break;
        }
        
        if ([self.delegate respondsToSelector:@selector(sourceSleepPeriodForReading:)])
        {
            NSTimeInterval sleepPeriod = [self.delegate sourceSleepPeriodForReading:self];
            if (sleepPeriod > 0)
            {
                [NSThread sleepForTimeInterval:sleepPeriod];
                continue;
            }
        }
        
        int readResult = av_read_frame(_formatContext, &packet);
        if (readResult < 0)
        {
            self.state = SGFFSourceStateReadFinished;
            break;
        }
        
        BOOL shouleReleasePacket = YES;
        if ([self.delegate respondsToSelector:@selector(source:didOutputPacket:)]) {
            shouleReleasePacket = ![self.delegate source:self didOutputPacket:packet];
        }
        if (shouleReleasePacket) {
            av_packet_unref(&packet);
        }
    }
}


#pragma mark - Callback

- (void)callbackForError
{
    self.state = SGFFSourceStateFailed;
    if ([self.delegate respondsToSelector:@selector(sourceDidFailed:)]) {
        [self.delegate sourceDidFailed:self];
    }
}

- (void)callbackForOpened
{
    self.state = SGFFSourceStateOpened;
    if ([self.delegate respondsToSelector:@selector(sourceDidOpened:)]) {
        [self.delegate sourceDidOpened:self];
    }
}

@end
