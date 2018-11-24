//
//  SGConcatSource.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGConcatSource.h"
#import "SGURLDemuxer2.h"
#import "SGPacket.h"
#import "SGError.h"
#import "SGMacro.h"

@interface SGConcatSource ()

@property (nonatomic, strong) SGConcatAsset * asset;
@property (nonatomic, readonly) SGSourceState state;
@property (nonatomic, strong) NSError * error;
@property (nonatomic) CMTime duration;
@property (nonatomic) BOOL seekable;
@property (nonatomic) CMTime seekTimeStamp;
@property (nonatomic) CMTime seekingTimeStamp;
@property (nonatomic, copy) void(^seekCompletionHandler)(CMTime, NSError *);

@property (nonatomic, strong) NSArray <SGURLDemuxer2 *> * formatContexts;
@property (nonatomic, strong) SGURLDemuxer2 * formatContext;
@property (nonatomic) BOOL audioEnable;
@property (nonatomic) BOOL videoEnable;
@property (nonatomic, strong) SGTrack * audioTrack;
@property (nonatomic, strong) SGTrack * videoTrack;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSOperation * openOperation;
@property (nonatomic, strong) NSOperation * readOperation;
@property (nonatomic, strong) NSCondition * pausedCondition;

@end

@implementation SGConcatSource

@synthesize delegate = _delegate;
@synthesize options = _options;
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

- (SGBlock)setState:(SGSourceState)state
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
    SGBlock callback = [self setState:SGSourceStateOpening];
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
    SGBlock callback = [self setState:SGSourceStateReading];
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
    SGBlock callback = [self setState:SGSourceStatePaused];
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
    SGBlock callback = [self setState:SGSourceStateReading];
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
    SGBlock callback = [self setState:SGSourceStateClosed];
    [self unlock];
    callback();
    [self.operationQueue cancelAllOperations];
    [self.operationQueue waitUntilAllOperationsAreFinished];
    self.operationQueue = nil;
    self.openOperation = nil;
    self.readOperation = nil;
    [self destroyFormatContext];
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

- (BOOL)seekToTime:(CMTime)time completionHandler:(SGSeekResult)completionHandler
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
    SGBlock callback = [self setState:SGSourceStateSeeking];
    self.seekTimeStamp = time;
    self.seekCompletionHandler = completionHandler;
    [self unlock];
    callback();
    return YES;
}

#pragma mark - Internal

- (void)destroyFormatContext
{
    for (SGURLDemuxer2 * obj in self.formatContexts)
    {
        [obj destroy];
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
    if (self.formatContext.seekable)
    {
        CMTime timeStamp = self.formatContext.actualTimeRange.start;
        long long par = AV_TIME_BASE * timeStamp.value / timeStamp.timescale;
        av_seek_frame(self.formatContext.coreFormatContext, -1, par, AVSEEK_FLAG_BACKWARD);
    }
}

- (int)seekFormatContextWithTimeStamp:(CMTime)timeStamp
{
    for (NSInteger i = self.formatContexts.count - 1; i >= 0; i--)
    {
        SGURLDemuxer2 * formatContext = [self.formatContexts objectAtIndex:i];
        if (i == 0 || CMTimeCompare(timeStamp, formatContext.startTime) >= 0)
        {
            [self setCurrentFormatContext:formatContext];
            break;
        }
    }
    timeStamp = CMTimeSubtract(timeStamp, self.formatContext.startTime);
    timeStamp = SGCMTimeDivide(timeStamp, self.formatContext.scale);
    timeStamp = CMTimeAdd(timeStamp, self.formatContext.actualTimeRange.start);
    long long par = AV_TIME_BASE * timeStamp.value / timeStamp.timescale;
    int success = av_seek_frame(self.formatContext.coreFormatContext, -1, par, AVSEEK_FLAG_BACKWARD);
    return success;
}

- (void)setCurrentFormatContext:(SGURLDemuxer2 *)formatContext
{
    self.formatContext = formatContext;
    self.audioTrack = self.formatContext.audioTracks.firstObject;
    self.videoTrack = self.formatContext.videoTracks.firstObject;
}

#pragma mark - Open

- (void)startOpenThread
{
    SGWeakify(self)
    self.openOperation = [NSBlockOperation blockOperationWithBlock:^{
        SGStrongify(self)
        [self openThread];
    }];
    self.openOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.openOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    self.openOperation.name = [NSString stringWithFormat:@"%@-Open-Queue", self.class];
    [self.operationQueue addOperation:self.openOperation];
}

- (void)openThread
{
    CMTime duration = kCMTimeZero;
    BOOL seekable = YES;
    BOOL audioEnable = YES;
    BOOL videoEnable = YES;
    NSMutableArray <SGURLDemuxer2 *> * formatContexts = [NSMutableArray array];
    for (SGURLAsset2 * obj in self.asset.assets)
    {
        SGURLDemuxer2 * formatContext = [[SGURLDemuxer2 alloc] initWithURL:obj.URL scale:obj.scale startTime:duration preferredTimeRange:obj.timeRange];
        BOOL success = [formatContext openWithOptions:self.options opaque:(__bridge void *)self callback:SGConcatSourceInterruptHandler];
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
    SGBlock callback = [self setState:state];
    [self unlock];
    [self changeToNextFormatContext];
    callback();
}

#pragma mark - Read

- (void)startReadThread
{
    SGWeakify(self)
    self.readOperation = [NSBlockOperation blockOperationWithBlock:^{
        SGStrongify(self)
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
                int success = [self seekFormatContextWithTimeStamp:seekingTimeStamp];
                [self lock];
                if (self.state == SGSourceStateSeeking &&
                    CMTimeCompare(self.seekTimeStamp, seekingTimeStamp) != 0)
                {
                    [self unlock];
                    continue;
                }
                SGBlock callback = [self setState:SGSourceStateReading];
                CMTime seekTimeStamp = self.seekTimeStamp;
                void(^seekCompletionHandler)(CMTime, NSError *) = self.seekCompletionHandler;
                self.seekTimeStamp = kCMTimeZero;
                self.seekingTimeStamp = kCMTimeZero;
                self.seekCompletionHandler = nil;
                [self unlock];
                callback();
                if (seekCompletionHandler)
                {
                    NSError * error = SGEGetError(success, SGOperationCodeFormatSeekFrame);
                    seekCompletionHandler(seekTimeStamp, error);
                }
                continue;
            }
            else if (self.state == SGSourceStateReading)
            {
//                [self unlock];
//                SGPacket * packet = [[SGObjectPool sharePool] objectWithClass:[SGPacket class]];
//                int readResult = av_read_frame(self.formatContext.coreFormatContext, packet.corePacket);
//                if (readResult < 0)
//                {
//                    if (readResult != AVERROR_EXIT)
//                    {
//                        [self lock];
//                        SGBlock callback = ^{};
//                        if (self.state == SGSourceStateReading)
//                        {
//                            if (self.formatContext == self.formatContexts.lastObject)
//                            {
//                                callback = [self setState:SGSourceStateFinished];
//                            }
//                            else
//                            {
//                                callback = ^{
//                                    [self changeToNextFormatContext];
//                                };
//                            }
//                        }
//                        [self unlock];
//                        callback();
//                    }
//                }
//                else
//                {
//                    SGTrack * track = nil;
//                    for (SGTrack * obj in self.formatContext.tracks)
//                    {
//                        if (obj.index == packet.corePacket->track_index)
//                        {
//                            track = obj;
//                            break;
//                        }
//                    }
//                    if ((self.audioEnable && track == self.audioTrack) ||
//                        (self.videoEnable && track == self.videoTrack))
//                    {
////                        [packet fillWithMediaType:track.mediaType
////                                         codecpar:track.coreTrack->codecpar
////                                         timebase:track.timebase
////                                            scale:self.formatContext.scale
////                                        startTime:self.formatContext.startTime
////                                        timeRange:self.formatContext.actualTimeRange];
//                        [self.delegate source:self hasNewPacket:packet];
//                    }
//                }
//                [packet unlock];
//                continue;
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
