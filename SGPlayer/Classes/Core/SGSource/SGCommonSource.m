//
//  SGCommonSource.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGCommonSource.h"
#import "SGFFmpeg.h"
#import "SGPacket.h"
#import "SGError.h"

@interface SGCommonSource () <NSLocking>

@property (nonatomic, assign) SGSourceState state;
@property (nonatomic, strong) NSError * error;
@property (nonatomic, assign) CMTime duration;
@property (nonatomic, strong) NSArray <SGStream *> * streams;
@property (nonatomic, strong) NSArray <SGStream *> * videoStreams;
@property (nonatomic, strong) NSArray <SGStream *> * audioStreams;
@property (nonatomic, strong) NSArray <SGStream *> * subtitleStreams;
@property (nonatomic, strong) NSArray <SGStream *> * otherStreams;
@property (nonatomic, assign) AVFormatContext * formatContext;
@property (nonatomic, strong) NSRecursiveLock * coreLock;
@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSInvocationOperation * openOperation;
@property (nonatomic, strong) NSInvocationOperation * readOperation;
@property (nonatomic, strong) NSCondition * pausedCondition;
@property (nonatomic, assign) BOOL seekable;
@property (nonatomic, assign) CMTime seekTimeStamp;
@property (nonatomic, assign) CMTime seekingTimeStamp;
@property (nonatomic, copy) void(^seekCompletionHandler)(BOOL, CMTime);

@end

@implementation SGCommonSource

@synthesize URL = _URL;
@synthesize delegate = _delegate;
@synthesize state = _state;

static int SGCommonSourceInterruptHandler(void * context)
{
    SGCommonSource * obj = (__bridge SGCommonSource *)context;
    [obj lock];
    int ret = NO;
    switch (obj.state)
    {
        case SGSourceStateFinished:
        case SGSourceStateClosed:
        case SGSourceStateFailed:
            ret = YES;
            break;
        case SGSourceStateSeeking:
            ret = CMTimeCompare(obj.seekTimeStamp, obj.seekingTimeStamp) != 0;
            break;
        default:
            break;
    }
    [obj unlock];
    return ret;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.duration = kCMTimeZero;
        self.seekable = NO;
        self.seekTimeStamp = kCMTimeZero;
        self.seekingTimeStamp = kCMTimeZero;
        self.pausedCondition = [[NSCondition alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    return self;
}

#pragma mark - Setter/Getter

- (void)setState:(SGSourceState)state
{
    [self lock];
    if (_state != state)
    {
        SGSourceState privious = _state;
        _state = state;
        if (privious == SGSourceStatePaused)
        {
            [self.pausedCondition lock];
            [self.pausedCondition broadcast];
            [self.pausedCondition unlock];
        }
        else if (privious == SGSourceStateFinished)
        {
            if (_state == SGSourceStateSeeking)
            {
                [self startReadThread];
            }
        }
        if ([self.delegate respondsToSelector:@selector(sourceDidChangeState:)])
        {
            [self.delegate sourceDidChangeState:self];
        }
    }
    [self unlock];
}

- (SGSourceState)state
{
    [self lock];
    SGSourceState ret = _state;
    [self unlock];
    return ret;
}

#pragma mark - Interface

- (void)open
{
    [self lock];
    if (self.state != SGSourceStateNone)
    {
        [self unlock];
        return;
    }
    self.state = SGSourceStateOpening;
    [self startOpenThread];
    [self unlock];
}

- (void)read
{
    [self lock];
    if (self.state != SGSourceStateOpened)
    {
        [self unlock];
        return;
    }
    self.state = SGSourceStateReading;
    [self startReadThread];
    [self unlock];
}

- (void)pause
{
    [self lock];
    if (self.state != SGSourceStateReading &&
        self.state != SGSourceStateSeeking &&
        self.state != SGSourceStateFinished)
    {
        [self unlock];
        return;
    }
    self.state = SGSourceStatePaused;
    [self unlock];
}

- (void)resume
{
    [self lock];
    if (self.state != SGSourceStatePaused)
    {
        [self unlock];
        return;
    }
    self.state = SGSourceStateReading;
    [self unlock];
}

- (void)close
{
    [self lock];
    if (self.state == SGSourceStateClosed)
    {
        [self unlock];
        return;
    }
    self.state = SGSourceStateClosed;
    [self unlock];
    [self.operationQueue cancelAllOperations];
    [self.operationQueue waitUntilAllOperationsAreFinished];
    if (self.formatContext)
    {
        avformat_close_input(&_formatContext);
        self.formatContext = NULL;
    }
}

#pragma mark - Seeking

- (BOOL)seekableToTime:(CMTime)time
{
    if (CMTIME_IS_INVALID(time))
    {
        return NO;
    }
    return self.seekable;
}

- (BOOL)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL, CMTime))completionHandler
{
    if (![self seekableToTime:time])
    {
        return NO;
    }
    [self lock];
    if (self.state != SGSourceStateReading &&
        self.state != SGSourceStatePaused &&
        self.state != SGSourceStateSeeking &&
        self.state != SGSourceStateFinished)
    {
        [self unlock];
        return NO;
    }
    self.state = SGSourceStateSeeking;
    self.seekTimeStamp = time;
    self.seekCompletionHandler = completionHandler;
    [self unlock];
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
    [SGFFmpeg setupIfNeeded];
    
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
    
    int64_t duration = self.formatContext->duration;
    if (duration > 0)
    {
        self.duration = CMTimeMake(duration, AV_TIME_BASE);
    }
    if (CMTimeCompare(self.duration, kCMTimeZero) > 0 &&
        self.formatContext->pb)
    {
        self.seekable = self.formatContext->pb->seekable;
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
        [self lock];
        if (self.state == SGSourceStateNone ||
            self.state == SGSourceStateFinished ||
            self.state == SGSourceStateClosed ||
            self.state == SGSourceStateFailed)
        {
            [self unlock];
            break;
        }
        else if (self.state == SGSourceStatePaused)
        {
            [self.pausedCondition lock];
            [self unlock];
            [self.pausedCondition wait];
            [self.pausedCondition unlock];
            continue;
        }
        else if (self.state == SGSourceStateSeeking)
        {
            self.seekingTimeStamp = self.seekTimeStamp;
            long long timeStamp = AV_TIME_BASE * self.seekingTimeStamp.value / self.seekingTimeStamp.timescale;
            [self unlock];
            int success = av_seek_frame(self.formatContext, -1, timeStamp, AVSEEK_FLAG_BACKWARD);
            [self lock];
            if (self.state == SGSourceStateSeeking)
            {
                long long currentTimeStamp = AV_TIME_BASE * self.seekTimeStamp.value / self.seekTimeStamp.timescale;
                if (timeStamp == currentTimeStamp)
                {
                    if (self.seekCompletionHandler)
                    {
                        self.seekCompletionHandler(success >= 0, self.seekTimeStamp);
                    }
                    self.seekTimeStamp = kCMTimeZero;
                    self.seekingTimeStamp = kCMTimeZero;
                    self.seekCompletionHandler = nil;
                    self.state = SGSourceStateReading;
                }
            }
            else
            {
                self.seekTimeStamp = kCMTimeZero;
                self.seekingTimeStamp = kCMTimeZero;
                self.seekCompletionHandler = nil;
            }
            [self unlock];
            continue;
        }
        else if (self.state == SGSourceStateReading)
        {
            [self unlock];
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

#pragma mark - NSLocking

- (void)lock
{
    if (!self.coreLock)
    {
        self.coreLock = [[NSRecursiveLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
