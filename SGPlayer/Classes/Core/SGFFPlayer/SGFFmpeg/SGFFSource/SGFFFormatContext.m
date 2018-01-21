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
        case SGFFSourceStateFinished:
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
@property (nonatomic, strong) NSCondition * readCondition;
@property (nonatomic, assign) long long seekingTimestamp;

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
    [self startOpenThread];
}

- (void)read
{
    self.state = SGFFSourceStateReading;
    [self startReadThread];
}

- (void)pause
{
    if (self.state == SGFFSourceStateReading)
    {
        self.state = SGFFSourceStatePaused;
    }
}

- (void)resume
{
    if (self.state == SGFFSourceStatePaused)
    {
        self.state = SGFFSourceStateReading;
        [self.readCondition lock];
        [self.readCondition signal];
        [self.readCondition unlock];
    }
}

- (void)close
{
    self.state = SGFFSourceStateClosed;
    [self.readCondition lock];
    [self.readCondition broadcast];
    [self.readCondition unlock];
    [self.operationQueue cancelAllOperations];
    [self.operationQueue waitUntilAllOperationsAreFinished];
    if (_formatContext)
    {
        avformat_close_input(&_formatContext);
        _formatContext = NULL;
    }
}

- (void)seekToTime:(NSTimeInterval)timestamp
{
    if (self.state == SGFFSourceStatePaused)
    {
        self.state = SGFFSourceStateSeeking;
        self.seekingTimestamp = timestamp * AV_TIME_BASE;
        [self.readCondition lock];
        [self.readCondition signal];
        [self.readCondition unlock];
    }
    else if (self.state == SGFFSourceStateReading)
    {
        self.state = SGFFSourceStateSeeking;
        self.seekingTimestamp = timestamp * AV_TIME_BASE;
    }
    else if (self.state == SGFFSourceStateFinished)
    {
        [self startReadThread];
        self.state = SGFFSourceStateSeeking;
        self.seekingTimestamp = timestamp * AV_TIME_BASE;
    }
}


#pragma mark - Thread

- (void)startOpenThread
{
    if (!self.operationQueue)
    {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 2;
        self.operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    self.openOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(openThread) object:nil];
    self.openOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.openOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.operationQueue addOperation:self.openOperation];
}

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
    
    self.state = SGFFSourceStateOpened;
    if ([self.delegate respondsToSelector:@selector(sourceDidOpened:)]) {
        [self.delegate sourceDidOpened:self];
    }
}

- (void)startReadThread
{
    if (!self.readCondition)
    {
        self.readCondition = [[NSCondition alloc] init];
    }
    self.readOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(readThread) object:nil];
    self.readOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.readOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.readOperation addDependency:self.openOperation];
    [self.operationQueue addOperation:self.readOperation];
}

- (void)readThread
{
    AVPacket packet;
    av_init_packet(&packet);
    while (YES)
    {
        if (self.state == SGFFSourceStateFinished
            || self.state == SGFFSourceStateClosed
            || self.state == SGFFSourceStateFailed)
        {
            break;
        }
        else if (self.state == SGFFSourceStatePaused)
        {
            [self.readCondition lock];
            [self.readCondition wait];
            [self.readCondition unlock];
            continue;
        }
        else if (self.state == SGFFSourceStateSeeking)
        {
            if (self.seekingTimestamp > 0)
            {
                av_seek_frame(_formatContext, -1, self.seekingTimestamp, AVSEEK_FLAG_BACKWARD);
                self.seekingTimestamp = 0;
            }
            self.state = SGFFSourceStateReading;
            [self.delegate sourceDidFinishedSeeking:self];
            continue;
        }
        else if (self.state == SGFFSourceStateReading)
        {
            int readResult = av_read_frame(_formatContext, &packet);
            if (readResult < 0)
            {
                self.state = SGFFSourceStateFinished;
                break;
            }
            [self.delegate source:self didOutputPacket:packet];
            continue;
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

@end
