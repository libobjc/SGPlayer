//
//  SGConcatSource.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGConcatSource.h"
#import "SGFormatContext.h"
#import "SGPacket.h"
#import "SGError.h"
#import "SGMacro.h"

@interface SGConcatSource ()

@property (nonatomic, strong) SGConcatAsset * asset;
@property (nonatomic, assign, readonly) SGSourceState state;
@property (nonatomic, strong) NSError * error;
@property (nonatomic, assign) CMTime duration;
@property (nonatomic, assign) BOOL seekable;
@property (nonatomic, assign) CMTime seekTimeStamp;
@property (nonatomic, assign) CMTime seekingTimeStamp;
@property (nonatomic, copy) void(^seekCompletionHandler)(BOOL, CMTime);

@property (nonatomic, strong) NSArray <SGFormatContext *> * formatContexts;
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
    for (SGFormatContext * obj in self.formatContexts)
    {
        [obj destory];
    }
    self.formatContext = nil;
    self.formatContexts = nil;
}

- (void)changeToNextFormatContext
{
    if (!self.formatContext)
    {
        [self setCurrentFormatContext:self.formatContexts.firstObject];
    }
    else if (self.formatContext != self.formatContexts.lastObject)
    {
        NSInteger index = [self.formatContexts indexOfObject:self.formatContext] + 1;
        [self setCurrentFormatContext:[self.formatContexts objectAtIndex:index]];
    }
}

- (int)changeFormatContextWithTimeStamp:(CMTime)timeStamp
{
    for (NSInteger i = self.formatContexts.count - 1; i >= 0; i--)
    {
        SGFormatContext * formatContext = [self.formatContexts objectAtIndex:i];
        if (i == 0 || CMTimeCompare(timeStamp, formatContext.offset) >= 0)
        {
            [self setCurrentFormatContext:formatContext];
            break;
        }
    }
    timeStamp = CMTimeSubtract(timeStamp, self.formatContext.offset);
    timeStamp = SGTimeDivideByTime(timeStamp, self.formatContext.scale);
    long long par = AV_TIME_BASE * timeStamp.value / timeStamp.timescale;
    int success = av_seek_frame(self.formatContext.coreFormatContext, -1, par, AVSEEK_FLAG_BACKWARD);
    return success;
}

- (void)setCurrentFormatContext:(SGFormatContext *)formatContext
{
    self.formatContext = formatContext;
    self.audioStream = self.formatContext.audioStreams.firstObject;
    self.videoStream = self.formatContext.videoStreams.firstObject;
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
    CMTime duration = kCMTimeZero;
    BOOL seekable = YES;
    BOOL audioEnable = YES;
    BOOL videoEnable = YES;
    NSMutableArray <SGFormatContext *> * formatContexts = [NSMutableArray array];
    for (SGURLAsset * obj in self.asset.assets)
    {
        SGFormatContext * formatContext = [[SGFormatContext alloc] initWithURL:obj.URL offset:duration scale:obj.scale];
        BOOL success = [formatContext openWithOpaque:(__bridge void *)self callback:SGConcatSourceInterruptHandler];
        if (success)
        {
            duration = CMTimeAdd(duration, formatContext.duration);
            seekable = seekable && formatContext.seekable;
            audioEnable = audioEnable && formatContext.audioEnable;
            videoEnable = videoEnable && formatContext.videoEnable;
            [formatContexts addObject:formatContext];
        }
        else
        {
            duration = kCMTimeZero;
            seekable = NO;
            audioEnable = NO;
            videoEnable = NO;
            formatContexts = nil;
            self.error = formatContext.error;
            break;
        }
    }
    self.formatContexts = formatContexts;
    self.duration = duration;
    self.seekable = seekable;
    self.audioEnable = audioEnable;
    self.videoEnable = videoEnable;
    [self lock];
    SGSourceState state = self.error ? SGSourceStateFailed : SGSourceStateOpened;
    SGBasicBlock callback = [self setState:state];
    [self changeToNextFormatContext];
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
            CMTime timeStamp = self.seekingTimeStamp;
            [self unlock];
            int success = [self changeFormatContextWithTimeStamp:timeStamp];
            [self lock];
            BOOL enable = NO;
            SGBasicBlock callback = ^{};
            if (self.state == SGSourceStateSeeking)
            {
                if (CMTimeCompare(self.seekTimeStamp, timeStamp) == 0)
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
            int readResult = av_read_frame(self.formatContext.coreFormatContext, packet.corePacket);
            if (readResult < 0)
            {
                [self lock];
                SGBasicBlock callback = ^{};
                if (self.state == SGSourceStateReading)
                {
                    if (self.formatContext == self.formatContexts.lastObject)
                    {
                        callback = [self setState:SGSourceStateFinished];
                    }
                    else
                    {
                        callback = ^{
                            [self changeToNextFormatContext];
                            if (self.formatContext.seekable)
                            {
                                av_seek_frame(self.formatContext.coreFormatContext, -1, 0, AVSEEK_FLAG_BACKWARD);
                            }
                        };
                    }
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
                if ((self.audioEnable && stream == self.audioStream) ||
                    (self.videoEnable && stream == self.videoStream))
                {
                    [packet fillWithStream:stream offset:self.formatContext.offset scale:self.formatContext.scale];
                    [self.delegate source:self hasNewPacket:packet];
                }
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
