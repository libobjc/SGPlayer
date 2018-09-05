//
//  SGURLSource.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGURLSource.h"
#import "SGFormatContext.h"
#import "SGPacket.h"
#import "SGError.h"
#import "SGMacro.h"

@interface SGURLSource () <NSLocking>

@property (nonatomic, strong) SGURLAsset * asset;
@property (nonatomic, assign, readonly) SGSourceState state;
@property (nonatomic, strong) NSError * error;
@property (nonatomic, assign) CMTime duration;
@property (nonatomic, assign) BOOL seekable;
@property (nonatomic, assign) CMTime seekTimeStamp;
@property (nonatomic, assign) CMTime seekingTimeStamp;
@property (nonatomic, copy) void(^seekCompletionHandler)(BOOL, CMTime);

@property (nonatomic, strong) SGFormatContext * formatContext;
@property (nonatomic, assign) BOOL audioEnable;
@property (nonatomic, assign) BOOL videoEnable;
@property (nonatomic, strong) SGStream * audioStream;
@property (nonatomic, strong) SGStream * videoStream;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSOperation * openOperation;
@property (nonatomic, strong) NSOperation * readOperation;
@property (nonatomic, strong) NSCondition * pausedCondition;

@end

@implementation SGURLSource

@synthesize delegate = _delegate;
@synthesize options = _options;
@synthesize state = _state;

static int SGURLSourceInterruptHandler(void * context)
{
    SGURLSource * obj = (__bridge SGURLSource *)context;
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

- (instancetype)initWithAsset:(SGURLAsset *)asset
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

- (NSDictionary *)metadata
{
    return self.formatContext.metadata;
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
    [self destoryFormatContext];
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

#pragma mark - Internal

- (void)destoryFormatContext
{
    [self.formatContext destory];
    self.formatContext = nil;
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
    self.openOperation.name = [NSString stringWithFormat:@"%@-Open-Queue", self.class];
    [self.operationQueue addOperation:self.openOperation];
}

- (void)openThread
{
    SGFormatContext * formatContext = [[SGFormatContext alloc] initWithURL:self.asset.URL scale:self.asset.scale startTime:kCMTimeZero preferredTimeRange:self.asset.timeRange];
    [formatContext openWithOptions:self.options opaque:(__bridge void *)self callback:SGURLSourceInterruptHandler];
    self.formatContext = formatContext;
    self.audioStream = self.formatContext.audioStreams.firstObject;
    self.videoStream = self.formatContext.videoStreams.firstObject;
    self.duration = self.formatContext.duration;
    self.seekable = self.formatContext.seekable;
    self.error = formatContext.error;
    [self lock];
    SGSourceState state = self.error ? SGSourceStateFailed : SGSourceStateOpened;
    SGBasicBlock callback = [self setState:state];
    [self unlock];
    callback();
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
    self.readOperation.name = [NSString stringWithFormat:@"%@-Read-Queue", self.class];
    [self.readOperation addDependency:self.openOperation];
    [self.operationQueue addOperation:self.readOperation];
}

- (void)readThread
{
    while (YES)
    {
        @autoreleasepool
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
                CMTime seekingTimeStamp = self.seekingTimeStamp;
                [self unlock];
                long long timeStamp = AV_TIME_BASE * seekingTimeStamp.value / seekingTimeStamp.timescale;
                int success = av_seek_frame(self.formatContext.coreFormatContext, -1, timeStamp, AVSEEK_FLAG_BACKWARD);
                [self lock];
                if (self.state == SGSourceStateSeeking &&
                    CMTimeCompare(self.seekTimeStamp, seekingTimeStamp) != 0)
                {
                    [self unlock];
                    continue;
                }
                SGBasicBlock callback = [self setState:SGSourceStateReading];
                CMTime seekTimeStamp = self.seekTimeStamp;
                void(^seekCompletionHandler)(BOOL, CMTime) = self.seekCompletionHandler;
                self.seekTimeStamp = kCMTimeZero;
                self.seekingTimeStamp = kCMTimeZero;
                self.seekCompletionHandler = nil;
                [self unlock];
                if (seekCompletionHandler)
                {
                    seekCompletionHandler(success >= 0, seekTimeStamp);
                }
                callback();
                continue;
            }
            else if (self.state == SGSourceStateReading)
            {
                [self unlock];
                SGPacket * packet = [[SGObjectPool sharePool] objectWithClass:[SGPacket class]];
                int readResult = av_read_frame(self.formatContext.coreFormatContext, packet.corePacket);
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
                    SGStream * stream = nil;
                    for (SGStream * obj in self.formatContext.streams)
                    {
                        if (obj.index == packet.corePacket->stream_index)
                        {
                            stream = obj;
                            break;
                        }
                    }
                    if (stream == self.audioStream || stream == self.videoStream)
                    {
                        [packet fillWithMediaType:stream.mediaType
                                         codecpar:stream.coreStream->codecpar
                                         timebase:stream.timebase
                                            scale:self.formatContext.scale
                                        startTime:self.formatContext.startTime
                                        timeRange:self.formatContext.actualTimeRange];
                        [self.delegate source:self hasNewPacket:packet];
                    }
                }
                [packet unlock];
                continue;
            }
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
