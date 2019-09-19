//
//  SGURLSource.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPacketOutput.h"
#import "SGAsset+Internal.h"
#import "SGDemuxable.h"
#import "SGError.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGPacketOutput () <SGDemuxableDelegate>

{
    struct {
        NSError *error;
        SGPacketOutputState state;
    } _flags;
    struct {
        CMTime seekTime;
        CMTime seekingTime;
        SGSeekResult seekResult;
    } _seekFlags;
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) NSCondition *wakeup;
@property (nonatomic, strong, readonly) id<SGDemuxable> demuxable;
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;

@end

@implementation SGPacketOutput

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self->_demuxable = [asset newDemuxable];
        self->_demuxable.delegate = self;
        self->_lock = [[NSLock alloc] init];
        self->_wakeup = [[NSCondition alloc] init];
    }
    return self;
}

- (void)dealloc
{
    SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.state != SGPacketOutputStateClosed;
    }, ^SGBlock {
        [self setState:SGPacketOutputStateClosed];
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
        return nil;
    });
}

#pragma mark - Mapping

SGGet0Map(CMTime, duration, self->_demuxable)
SGGet0Map(NSDictionary *, metadata, self->_demuxable)
SGGet0Map(NSArray<SGTrack *> *, tracks, self->_demuxable)
SGGet0Map(SGDemuxerOptions *, options, self->_demuxable)
SGSet1Map(void, setOptions, SGDemuxerOptions *, self->_demuxable)

#pragma mark - Setter & Getter

- (SGBlock)setState:(SGPacketOutputState)state
{
    if (self->_flags.state == state) {
        return ^{};
    }
    self->_flags.state = state;
    [self->_wakeup lock];
    [self->_wakeup broadcast];
    [self->_wakeup unlock];
    return ^{
        [self->_delegate packetOutput:self didChangeState:state];
    };
}

- (SGPacketOutputState)state
{
    __block SGPacketOutputState ret = SGPacketOutputStateNone;
    SGLockEXE00(self->_lock, ^{
        ret = self->_flags.state;
    });
    return ret;
}

- (NSError *)error
{
    __block NSError *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_flags.error copy];
    });
    return ret;
}

#pragma mark - Control

- (BOOL)open
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == SGPacketOutputStateNone;
    }, ^SGBlock {
        return [self setState:SGPacketOutputStateOpening];
    }, ^BOOL(SGBlock block) {
        block();
        NSOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(runningThread) object:nil];
        self->_operationQueue = [[NSOperationQueue alloc] init];
        self->_operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
        [self->_operationQueue addOperation:operation];
        return YES;
    });
}

- (BOOL)close
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state != SGPacketOutputStateClosed;
    }, ^SGBlock {
        return [self setState:SGPacketOutputStateClosed];
    }, ^BOOL(SGBlock block) {
        block();
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state == SGPacketOutputStateReading ||
        self->_flags.state == SGPacketOutputStateSeeking;
    }, ^SGBlock {
        return [self setState:SGPacketOutputStatePaused];
    });
}

- (BOOL)resume
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state == SGPacketOutputStatePaused ||
        self->_flags.state == SGPacketOutputStateOpened;
    }, ^SGBlock {
        return [self setState:SGPacketOutputStateReading];
    });
}

#pragma mark - Seeking

- (BOOL)seekable
{
    return [self->_demuxable seekable] == nil;
}

- (BOOL)seekToTime:(CMTime)time result:(SGSeekResult)result
{
    if (![self seekable]) {
        return NO;
    }
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state == SGPacketOutputStateReading ||
        self->_flags.state == SGPacketOutputStatePaused ||
        self->_flags.state == SGPacketOutputStateSeeking ||
        self->_flags.state == SGPacketOutputStateFinished;
    }, ^SGBlock {
        SGBlock b1 = ^{}, b2 = ^{};
        if (self->_seekFlags.seekResult) {
            CMTime lastSeekTime = self->_seekFlags.seekTime;
            SGSeekResult lastSeekResult = self->_seekFlags.seekResult;
            b1 = ^{
                lastSeekResult(lastSeekTime,
                               SGCreateError(SGErrorCodePacketOutputCancelSeek,
                                              SGActionCodePacketOutputSeek));
            };
        }
        self->_seekFlags.seekTime = time;
        self->_seekFlags.seekResult = [result copy];
        b2 = [self setState:SGPacketOutputStateSeeking];
        return ^{
            b1(); b2();
        };
    });
}

#pragma mark - Threading

- (void)runningThread
{
    while (YES) {
        @autoreleasepool {
            [self->_lock lock];
            if (self->_flags.state == SGPacketOutputStateNone ||
                self->_flags.state == SGPacketOutputStateClosed ||
                self->_flags.state == SGPacketOutputStateFailed) {
                [self->_lock unlock];
                break;
            } else if (self->_flags.state == SGPacketOutputStateOpening) {
                [self->_lock unlock];
                NSError *error = [self->_demuxable open];
                [self->_lock lock];
                if (self->_flags.state != SGPacketOutputStateOpening) {
                    [self->_lock unlock];
                    continue;
                }
                self->_flags.error = error;
                SGBlock b1 = [self setState:error ? SGPacketOutputStateFailed : SGPacketOutputStateOpened];
                [self->_lock unlock];
                b1();
                continue;
            } else if (self->_flags.state == SGPacketOutputStateOpened ||
                       self->_flags.state == SGPacketOutputStatePaused ||
                       self->_flags.state == SGPacketOutputStateFinished) {
                [self->_wakeup lock];
                [self->_lock unlock];
                [self->_wakeup wait];
                [self->_wakeup unlock];
                continue;
            } else if (self->_flags.state == SGPacketOutputStateSeeking) {
                self->_seekFlags.seekingTime = self->_seekFlags.seekTime;
                CMTime seeking_time = self->_seekFlags.seekingTime;
                [self->_lock unlock];
                NSError *error = [self->_demuxable seekToTime:seeking_time];
                [self->_lock lock];
                if (self->_flags.state == SGPacketOutputStateSeeking &&
                    CMTimeCompare(self->_seekFlags.seekTime, seeking_time) != 0) {
                    [self->_lock unlock];
                    continue;
                }
                SGBlock b1 = ^{}, b2 = ^{};
                if (self->_seekFlags.seekResult) {
                    CMTime seekTime = self->_seekFlags.seekTime;
                    SGSeekResult seek_result = self->_seekFlags.seekResult;
                    b1 = ^{
                        seek_result(seekTime, error);
                    };
                }
                if (self->_flags.state == SGPacketOutputStateSeeking) {
                    b2 = [self setState:SGPacketOutputStateReading];
                }
                self->_seekFlags.seekTime = kCMTimeZero;
                self->_seekFlags.seekingTime = kCMTimeZero;
                self->_seekFlags.seekResult = nil;
                [self->_lock unlock];
                b1(); b2();
                continue;
            } else if (self->_flags.state == SGPacketOutputStateReading) {
                [self->_lock unlock];
                SGPacket *packet = nil;
                NSError *error = [self->_demuxable nextPacket:&packet];
                if (error) {
                    SGLockCondEXE10(self->_lock, ^BOOL {
                        return self->_flags.state == SGPacketOutputStateReading;
                    }, ^SGBlock{
                        return [self setState:SGPacketOutputStateFinished];
                    });
                } else {
                    [self->_delegate packetOutput:self didOutputPacket:packet];
                    [packet unlock];
                }
                continue;
            }
        }
    }
    [self->_demuxable close];
}

#pragma mark - SGDemuxableDelegate

- (BOOL)demuxableShouldAbortBlockingFunctions:(id<SGDemuxable>)demuxable
{
    return SGLockCondEXE00(self->_lock, ^BOOL {
        switch (self->_flags.state) {
            case SGPacketOutputStateFinished:
            case SGPacketOutputStateClosed:
            case SGPacketOutputStateFailed:
                return YES;
            default:
                return NO;
        }
    }, nil);
}

@end
