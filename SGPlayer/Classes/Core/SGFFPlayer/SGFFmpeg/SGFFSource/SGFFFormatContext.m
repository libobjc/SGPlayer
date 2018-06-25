//
//  SGFFFormatContext.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFFormatContext.h"
#import "SGFFPacket.h"
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

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, weak) id <SGFFSourceDelegate> delegate;
@property (nonatomic, assign) SGFFSourceState state;
@property (nonatomic, copy) NSError * error;

@property (nonatomic, strong) NSArray <SGFFStream *> * streams;
@property (nonatomic, strong) NSArray <SGFFStream *> * videoStreams;
@property (nonatomic, strong) NSArray <SGFFStream *> * audioStreams;
@property (nonatomic, strong) NSArray <SGFFStream *> * subtitleStreams;
@property (nonatomic, strong) NSArray <SGFFStream *> * otherStreams;

@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSInvocationOperation * openOperation;
@property (nonatomic, strong) NSInvocationOperation * readOperation;
@property (nonatomic, strong) NSCondition * readCondition;
@property (nonatomic, assign) long long seekingTimestamp;
@property (nonatomic, copy) void(^seekingCompletionHandler)(BOOL);

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

#pragma mark - Setter/Getter

- (CMTime)duration
{
    if (!_formatContext)
    {
        return kCMTimeZero;
    }
    int64_t duration = _formatContext->duration;
    if (duration < 0)
    {
        return kCMTimeZero;
    }
    return CMTimeMake(duration, AV_TIME_BASE);
}

#pragma mark - Interface

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
        [self.readCondition broadcast];
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

- (BOOL)seekable
{
    if (!_formatContext)
    {
        return NO;
    }
    BOOL seekable = YES;
    if (_formatContext->pb)
    {
        seekable = _formatContext->pb->seekable;
    }
    if (seekable && CMTimeCompare(self.duration, kCMTimeZero) > 0)
    {
        return YES;
    }
    return NO;
}

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler
{
    if (self.state == SGFFSourceStatePaused)
    {
        self.seekingTimestamp = time.value * AV_TIME_BASE / time.timescale;
        self.seekingCompletionHandler = completionHandler;
        self.state = SGFFSourceStateSeeking;
        [self.readCondition lock];
        [self.readCondition signal];
        [self.readCondition unlock];
    }
    else if (self.state == SGFFSourceStateReading)
    {
        self.seekingTimestamp = time.value * AV_TIME_BASE / time.timescale;
        self.seekingCompletionHandler = completionHandler;
        self.state = SGFFSourceStateSeeking;
    }
    else if (self.state == SGFFSourceStateFinished)
    {
        self.seekingTimestamp = time.value * AV_TIME_BASE / time.timescale;
        self.seekingCompletionHandler = completionHandler;
        self.state = SGFFSourceStateSeeking;
        [self startReadThread];
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
        if (_formatContext)
        {
            avformat_free_context(_formatContext);
        }
        [self callbackForError];
        return;
    }
    
    reslut = avformat_find_stream_info(_formatContext, NULL);
    self.error = SGFFGetErrorCode(reslut, SGFFErrorCodeFormatFindStreamInfo);
    if (self.error)
    {
        if (_formatContext)
        {
            avformat_close_input(&_formatContext);
            avformat_free_context(_formatContext);
        }
        [self callbackForError];
        return;
    }
    
    NSMutableArray <SGFFStream *> * streams = [NSMutableArray array];
    NSMutableArray <SGFFStream *> * audioStreams = [NSMutableArray array];
    NSMutableArray <SGFFStream *> * videoStreams = [NSMutableArray array];
    NSMutableArray <SGFFStream *> * subtitleStreams = [NSMutableArray array];
    NSMutableArray <SGFFStream *> * otherStreams = [NSMutableArray array];
    for (int i = 0; i < _formatContext->nb_streams; i++)
    {
        SGFFStream * obj = [[SGFFStream alloc] init];
        obj.coreStream = _formatContext->streams[i];
        [streams addObject:obj];
        switch (obj.coreStream->codecpar->codec_type)
        {
            case AVMEDIA_TYPE_AUDIO:
                [audioStreams addObject:obj];
                break;
            case AVMEDIA_TYPE_VIDEO:
                [videoStreams addObject:obj];
                break;
            case AVMEDIA_TYPE_SUBTITLE:
                [subtitleStreams addObject:obj];
                break;
            default:
                [otherStreams addObject:obj];
                break;
        }
    }
    self.streams = [streams copy];
    self.audioStreams = [audioStreams copy];
    self.videoStreams = [videoStreams copy];
    self.subtitleStreams = [subtitleStreams copy];
    self.otherStreams = [otherStreams copy];
    
    if (self.audioStreams.count > 0 || self.videoStreams.count > 0)
    {
        self.state = SGFFSourceStateOpened;
        if ([self.delegate respondsToSelector:@selector(sourceDidOpened:)])
        {
            [self.delegate sourceDidOpened:self];
        }
    }
    else
    {
        [self callbackForError];
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
    while (YES)
    {
        if (self.state == SGFFSourceStateFinished ||
            self.state == SGFFSourceStateClosed ||
            self.state == SGFFSourceStateFailed)
        {
            break;
        }
        else if (self.state == SGFFSourceStatePaused)
        {
            [self.readCondition lock];
            if (self.state == SGFFSourceStatePaused)
            {
                [self.readCondition wait];
            }
            [self.readCondition unlock];
            continue;
        }
        else if (self.state == SGFFSourceStateSeeking)
        {
            av_seek_frame(_formatContext, -1, self.seekingTimestamp, AVSEEK_FLAG_BACKWARD);
            if (self.seekingCompletionHandler)
            {
                self.seekingCompletionHandler(YES);
            }
            self.seekingTimestamp = 0;
            self.seekingCompletionHandler = nil;
            self.state = SGFFSourceStateReading;
            continue;
        }
        else if (self.state == SGFFSourceStateReading)
        {
            SGFFPacket * packet = [[SGFFObjectPool sharePool] objectWithClass:[SGFFPacket class]];
            int readResult = av_read_frame(_formatContext, packet.corePacket);
            if (readResult < 0)
            {
                self.state = SGFFSourceStateFinished;
                [packet unlock];
                if ([self.delegate respondsToSelector:@selector(sourceDidFinished:)]) {
                    [self.delegate sourceDidFinished:self];
                }
                break;
            }
            [self.delegate source:self hasNewPacket:packet];
            [packet unlock];
            continue;
        }
    }
}

#pragma mark - Callback

- (void)callbackForError
{
    self.state = SGFFSourceStateFailed;
    if ([self.delegate respondsToSelector:@selector(sourceDidFailed:)])
    {
        [self.delegate sourceDidFailed:self];
    }
}

@end
