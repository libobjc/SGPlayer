//
//  SGConcatSource.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGConcatSource.h"
#import "SGPacket.h"
#import "SGError.h"
#import "SGMacro.h"

@interface SGConcatSource ()

@property (nonatomic, strong) SGConcatAsset * asset;
@property (nonatomic, assign, readonly) SGSourceState state;
@property (nonatomic, strong) NSError * error;
@property (nonatomic, assign) CMTime duration;
@property (nonatomic, strong) NSArray <SGStream *> * streams;
@property (nonatomic, strong) NSArray <SGStream *> * videoStreams;
@property (nonatomic, strong) NSArray <SGStream *> * audioStreams;
@property (nonatomic, strong) NSArray <SGStream *> * subtitleStreams;
@property (nonatomic, strong) NSArray <SGStream *> * otherStreams;
@property (nonatomic, assign) AVFormatContext * formatContext;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSOperation * openOperation;
@property (nonatomic, strong) NSOperation * readOperation;
@property (nonatomic, strong) NSCondition * pausedCondition;
@property (nonatomic, assign) BOOL seekable;
@property (nonatomic, assign) CMTime seekTimeStamp;
@property (nonatomic, assign) CMTime seekingTimeStamp;
@property (nonatomic, copy) void(^seekCompletionHandler)(BOOL, CMTime);

@end

@implementation SGConcatSource

@synthesize delegate = _delegate;
@synthesize state = _state;

static int SGConcatSourceInterruptHandler(void * context)
{
    SGConcatSource * obj = (__bridge SGConcatSource *)context;
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

- (instancetype)initWithAsset:(SGConcatAsset *)asset
{
    if (self = [super init])
    {
        self.asset = asset;
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

- (void)dealloc
{
    
}

#pragma mark - Setter & Getter

- (SGBasicBlock)setState:(SGSourceState)state
{
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
        return ^{
            [self.delegate sourceDidChangeState:self];
        };
    }
    return ^{};
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
    SGBasicBlock callback = [self setState:SGSourceStateOpening];
    [self unlock];
    callback();
    [self startOpenThread];
}

- (void)read
{
    [self lock];
    if (self.state != SGSourceStateOpened)
    {
        [self unlock];
        return;
    }
    SGBasicBlock callback = [self setState:SGSourceStateReading];
    [self unlock];
    callback();
    [self startReadThread];
}

- (void)pause
{
    [self lock];
    if (self.state != SGSourceStateReading &&
        self.state != SGSourceStateSeeking)
    {
        [self unlock];
        return;
    }
    SGBasicBlock callback = [self setState:SGSourceStatePaused];
    [self unlock];
    callback();
}

- (void)resume
{
    [self lock];
    if (self.state != SGSourceStatePaused)
    {
        [self unlock];
        return;
    }
    SGBasicBlock callback = [self setState:SGSourceStateReading];
    [self unlock];
    callback();
}

- (void)close
{
    [self lock];
    if (self.state == SGSourceStateClosed)
    {
        [self unlock];
        return;
    }
    SGBasicBlock callback = [self setState:SGSourceStateClosed];
    [self unlock];
    callback();
    [self.operationQueue cancelAllOperations];
    [self.operationQueue waitUntilAllOperationsAreFinished];
    self.operationQueue = nil;
    self.openOperation = nil;
    self.readOperation = nil;
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
    SGBasicBlock callback = [self setState:SGSourceStateSeeking];
    self.seekTimeStamp = time;
    self.seekCompletionHandler = completionHandler;
    [self unlock];
    callback();
    return YES;
}

#pragma mark - Open

- (void)startOpenThread
{
    SGWeakSelf
    self.openOperation = [NSBlockOperation blockOperationWithBlock:^{
        SGStrongSelf
        [self openThread];
    }];
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
        [self setState:SGSourceStateFailed]();
        return;
    }
    
    self.formatContext->interrupt_callback.callback = SGConcatSourceInterruptHandler;
    self.formatContext->interrupt_callback.opaque = (__bridge void *)self;
    
    NSString * URLString = self.asset.units.firstObject.URL.isFileURL ? self.asset.units.firstObject.URL.path : self.asset.units.firstObject.URL.absoluteString;
    int reslut = avformat_open_input(&_formatContext, URLString.UTF8String, NULL, NULL);
    self.error = SGFFGetErrorCode(reslut, SGErrorCodeFormatOpenInput);
    if (self.error)
    {
        if (self.formatContext)
        {
            avformat_free_context(self.formatContext);
        }
        [self setState:SGSourceStateFailed]();
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
        [self setState:SGSourceStateFailed]();
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
        [self setState:SGSourceStateOpened]();
    }
    else
    {
        [self setState:SGSourceStateFailed]();
    }
}

#pragma mark - Read

- (void)startReadThread
{
    SGWeakSelf
    self.readOperation = [NSBlockOperation blockOperationWithBlock:^{
        SGStrongSelf
        [self readThread];
    }];
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
            BOOL enable = NO;
            SGBasicBlock callback = ^{};
            if (self.state == SGSourceStateSeeking)
            {
                long long current = AV_TIME_BASE * self.seekTimeStamp.value / self.seekTimeStamp.timescale;
                if (timeStamp == current)
                {
                    enable = YES;
                    callback = [self setState:SGSourceStateReading];
                }
            }
            CMTime seekTimeStamp = self.seekTimeStamp;
            void(^seekCompletionHandler)(BOOL, CMTime) = self.seekCompletionHandler;
            self.seekTimeStamp = kCMTimeZero;
            self.seekingTimeStamp = kCMTimeZero;
            self.seekCompletionHandler = nil;
            [self unlock];
            if (enable)
            {
                if (seekCompletionHandler)
                {
                    seekCompletionHandler(success >= 0, seekTimeStamp);
                }
                callback();
            }
            continue;
        }
        else if (self.state == SGSourceStateReading)
        {
            [self unlock];
            SGPacket * packet = [[SGObjectPool sharePool] objectWithClass:[SGPacket class]];
            int readResult = av_read_frame(self.formatContext, packet.corePacket);
            if (readResult < 0)
            {
                [self lock];
                SGBasicBlock callback = ^{};
                if (self.state == SGSourceStateReading)
                {
                    callback = [self setState:SGSourceStateFinished];
                }
                [self unlock];
                callback();
            }
            else
            {
                [self.delegate source:self hasNewPacket:packet];
            }
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
        self.coreLock = [[NSLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
