//
//  SGCommonSource.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGCommonSource.h"
#import "SGPacket.h"
#import "SGError.h"
#import "avformat.h"

@interface SGCommonSource ()

@property (nonatomic, assign) AVFormatContext * formatContext;

@property (nonatomic, assign) SGSourceState state;
@property (nonatomic, copy) NSError * error;

@property (nonatomic, strong) NSArray <SGStream *> * streams;
@property (nonatomic, strong) NSArray <SGStream *> * videoStreams;
@property (nonatomic, strong) NSArray <SGStream *> * audioStreams;
@property (nonatomic, strong) NSArray <SGStream *> * subtitleStreams;
@property (nonatomic, strong) NSArray <SGStream *> * otherStreams;

@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSInvocationOperation * openOperation;
@property (nonatomic, strong) NSInvocationOperation * readOperation;
@property (nonatomic, strong) NSCondition * readingCondition;

@property (nonatomic, assign) long long seekTimestamp;
@property (nonatomic, assign) long long seekingTimestamp;
@property (nonatomic, copy) void(^seekCompletionHandler)(BOOL);

@end

@implementation SGCommonSource

@synthesize URL = _URL;
@synthesize delegate = _delegate;

static int SGCommonSourceInterruptHandler(void * context)
{
    SGCommonSource * obj = (__bridge SGCommonSource *)context;
    switch (obj.state)
    {
        case SGSourceStateFinished:
        case SGSourceStateStoped:
        case SGSourceStateFailed:
            return YES;
        case SGSourceStateSeeking:
            if (obj.seekTimestamp != obj.seekingTimestamp)
            {
                return YES;
            }
        default:
            return NO;
    }
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.readingCondition = [[NSCondition alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    return self;
}

#pragma mark - Setter/Getter

- (void)setState:(SGSourceState)state
{
    if (_state != state)
    {
        _state = state;
        if ([self.delegate respondsToSelector:@selector(sourceDidChangeState:)])
        {
            [self.delegate sourceDidChangeState:self];
        }
    }
}

- (CMTime)duration
{
    switch (self.state)
    {
        case SGSourceStateReading:
        case SGSourceStateSeeking:
        case SGSourceStateFinished:
            break;
        default:
            return kCMTimeZero;
    }
    if (!self.formatContext)
    {
        return kCMTimeZero;
    }
    int64_t duration = self.formatContext->duration;
    if (duration < 0)
    {
        return kCMTimeZero;
    }
    return CMTimeMake(duration, AV_TIME_BASE);
}

#pragma mark - Interface

- (void)open
{
    if (self.state != SGSourceStateIdle)
    {
        return;
    }
    self.state = SGSourceStateOpening;
    [self startOpenThread];
}

- (void)read
{
    if (self.state != SGSourceStateOpened)
    {
        return;
    }
    self.state = SGSourceStateReading;
    [self startReadThread];
}

- (void)pause
{
    if (self.state != SGSourceStateReading ||
        self.state != SGSourceStateSeeking)
    {
        return;
    }
    self.state = SGSourceStatePaused;
}

- (void)resume
{
    if (self.state != SGSourceStatePaused)
    {
        return;
    }
    self.state = SGSourceStateReading;
    [self.readingCondition lock];
    [self.readingCondition broadcast];
    [self.readingCondition unlock];
}

- (void)close
{
    if (self.state == SGSourceStateStoped)
    {
        return;
    }
    self.state = SGSourceStateStoped;
    [self.readingCondition lock];
    [self.readingCondition broadcast];
    [self.readingCondition unlock];
    [self.operationQueue cancelAllOperations];
    [self.operationQueue waitUntilAllOperationsAreFinished];
    if (self.formatContext)
    {
        avformat_close_input(&_formatContext);
        self.formatContext = NULL;
    }
}

#pragma mark - Seeking

- (BOOL)seekable
{
    switch (self.state)
    {
        case SGSourceStateIdle:
        case SGSourceStateOpening:
        case SGSourceStateOpened:
        case SGSourceStateStoped:
        case SGSourceStateFailed:
            return NO;
        case SGSourceStateReading:
        case SGSourceStatePaused:
        case SGSourceStateSeeking:
        case SGSourceStateFinished:
            break;
    }
    if (!self.formatContext)
    {
        return NO;
    }
    if (CMTimeCompare(self.duration, kCMTimeZero) <= 0)
    {
        return NO;
    }
    if (!self.formatContext->pb)
    {
        return NO;
    }
    if (!self.formatContext->pb->seekable)
    {
        return NO;
    }
    return YES;
}

- (BOOL)seekableToTime:(CMTime)time
{
    if (CMTIME_IS_INVALID(time))
    {
        return NO;
    }
    return self.seekable;
}

- (BOOL)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler
{
    if (![self seekableToTime:time])
    {
        return NO;
    }
    self.seekTimestamp = time.value * AV_TIME_BASE / time.timescale;
    self.seekCompletionHandler = completionHandler;
    SGSourceState state = self.state;
    self.state = SGSourceStateSeeking;
    if (state == SGSourceStatePaused)
    {
        [self.readingCondition lock];
        [self.readingCondition broadcast];
        [self.readingCondition unlock];
    }
    else if (state == SGSourceStateFinished)
    {
        [self startReadThread];
    }
    return YES;
}

#pragma mark - Open

- (void)startOpenThread
{
    self.openOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(openThread) object:nil];
    self.openOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.openOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.operationQueue addOperation:self.openOperation];
}

- (void)openThread
{
    self.formatContext = avformat_alloc_context();
    
    if (!self.formatContext)
    {
        self.error = SGFFCreateErrorCode(SGErrorCodeFormatCreate);
        self.state = SGSourceStateFailed;
        return;
    }
    
    self.formatContext->interrupt_callback.callback = SGCommonSourceInterruptHandler;
    self.formatContext->interrupt_callback.opaque = (__bridge void *)self;
    
    NSString * URLString = self.URL.isFileURL ? self.URL.path : self.URL.absoluteString;
    int reslut = avformat_open_input(&_formatContext, URLString.UTF8String, NULL, NULL);
    self.error = SGFFGetErrorCode(reslut, SGErrorCodeFormatOpenInput);
    if (self.error)
    {
        if (self.formatContext)
        {
            avformat_free_context(self.formatContext);
        }
        self.state = SGSourceStateFailed;
        return;
    }
    
    reslut = avformat_find_stream_info(self.formatContext, NULL);
    self.error = SGFFGetErrorCode(reslut, SGErrorCodeFormatFindStreamInfo);
    if (self.error)
    {
        if (self.formatContext)
        {
            avformat_close_input(&_formatContext);
            avformat_free_context(self.formatContext);
        }
        self.state = SGSourceStateFailed;
        return;
    }
    
    NSMutableArray <SGStream *> * streams = [NSMutableArray array];
    NSMutableArray <SGStream *> * audioStreams = [NSMutableArray array];
    NSMutableArray <SGStream *> * videoStreams = [NSMutableArray array];
    NSMutableArray <SGStream *> * subtitleStreams = [NSMutableArray array];
    NSMutableArray <SGStream *> * otherStreams = [NSMutableArray array];
    for (int i = 0; i < self.formatContext->nb_streams; i++)
    {
        SGStream * obj = [[SGStream alloc] init];
        obj.coreStream = self.formatContext->streams[i];
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
        self.state = SGSourceStateOpened;
    }
    else
    {
        self.state = SGSourceStateFailed;
    }
}

#pragma mark - Read

- (void)startReadThread
{
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
        if (self.state == SGSourceStateFinished ||
            self.state == SGSourceStateStoped ||
            self.state == SGSourceStateFailed)
        {
            break;
        }
        else if (self.state == SGSourceStatePaused)
        {
            [self.readingCondition lock];
            if (self.state == SGSourceStatePaused)
            {
                [self.readingCondition wait];
            }
            [self.readingCondition unlock];
            continue;
        }
        else if (self.state == SGSourceStateSeeking)
        {
            while (YES)
            {
                self.seekingTimestamp = self.seekTimestamp;
                int success = av_seek_frame(self.formatContext, -1, self.seekingTimestamp, AVSEEK_FLAG_BACKWARD);
                if (self.state == SGSourceStateSeeking)
                {
                    if (self.seekTimestamp != self.seekingTimestamp)
                    {
                        continue;
                    }
                    if (self.seekCompletionHandler)
                    {
                        self.seekCompletionHandler(success >= 0);
                    }
                    self.seekTimestamp = 0;
                    self.seekingTimestamp = 0;
                    self.seekCompletionHandler = nil;
                    self.state = SGSourceStateReading;
                }
                else
                {
                    self.seekTimestamp = 0;
                    self.seekingTimestamp = 0;
                    self.seekCompletionHandler = nil;
                }
                break;
            }
            continue;
        }
        else if (self.state == SGSourceStateReading)
        {
            SGPacket * packet = [[SGObjectPool sharePool] objectWithClass:[SGPacket class]];
            int readResult = av_read_frame(self.formatContext, packet.corePacket);
            if (readResult < 0)
            {
                self.state = SGSourceStateFinished;
                [packet unlock];
                break;
            }
            [self.delegate source:self hasNewPacket:packet];
            [packet unlock];
            continue;
        }
    }
}

@end
