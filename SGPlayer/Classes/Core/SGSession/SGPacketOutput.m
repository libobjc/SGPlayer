//
//  SGURLSource.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPacketOutput.h"
#import "SGError.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGPacketOutput () <SGDemuxableDelegate>

{
    NSLock *_lock;
    NSError *_error;
    CMTime _seek_time;
    CMTime _seeking_time;
    NSCondition *_wakeup;
    SGSeekResult _seek_result;
    id<SGDemuxable> _demuxable;
    SGPacketOutputState _state;
    NSOperationQueue *_operation_queue;
}

@end

@implementation SGPacketOutput

- (instancetype)initWithDemuxable:(id<SGDemuxable>)demuxable
{
    if (self = [super init]) {
        self->_demuxable = demuxable;
        self->_demuxable.delegate = self;
        self->_lock = [[NSLock alloc] init];
        self->_wakeup = [[NSCondition alloc] init];
    }
    return self;
}

- (void)dealloc
{
    SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_state != SGPacketOutputStateClosed;
    }, ^SGBlock {
        [self setState:SGPacketOutputStateClosed];
        [self->_operation_queue cancelAllOperations];
        [self->_operation_queue waitUntilAllOperationsAreFinished];
        return nil;
    });
}

#pragma mark - Mapping

SGGet0Map(CMTime, duration, self->_demuxable)
SGGet0Map(NSDictionary *, metadata, self->_demuxable)
SGGet0Map(NSArray<SGTrack *> *, tracks, self->_demuxable)

#pragma mark - Setter & Getter

- (NSError *)error
{
    __block NSError *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_error copy];
    });
    return ret;
}

- (SGBlock)setState:(SGPacketOutputState)state
{
    if (_state == state) {
        return ^{};
    }
    _state = state;
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
        ret = self->_state;
    });
    return ret;
}

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state == SGPacketOutputStateNone;
    }, ^SGBlock {
        return [self setState:SGPacketOutputStateOpening];
    }, ^BOOL(SGBlock block) {
        block();
        NSOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(runningThread) object:nil];
        self->_operation_queue = [[NSOperationQueue alloc] init];
        self->_operation_queue.qualityOfService = NSQualityOfServiceUserInteractive;
        [self->_operation_queue addOperation:operation];
        return YES;
    });
}

- (BOOL)close
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state != SGPacketOutputStateClosed;
    }, ^SGBlock {
        return [self setState:SGPacketOutputStateClosed];
    }, ^BOOL(SGBlock block) {
        block();
        [self->_operation_queue cancelAllOperations];
        [self->_operation_queue waitUntilAllOperationsAreFinished];
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_state == SGPacketOutputStateReading || self->_state == SGPacketOutputStateSeeking;
    }, ^SGBlock {
        return [self setState:SGPacketOutputStatePaused];
    });
}

- (BOOL)resume
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_state == SGPacketOutputStatePaused || self->_state == SGPacketOutputStateOpened;
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
        return self->_state == SGPacketOutputStateReading || self->_state == SGPacketOutputStatePaused || self->_state == SGPacketOutputStateSeeking || self->_state == SGPacketOutputStateFinished;
    }, ^SGBlock {
        SGBlock b1 = ^{}, b2 = ^{};
        if (self->_seek_result) {
            CMTime lastSeekTime = self->_seek_time;
            SGSeekResult lastSeekResult = self->_seek_result;
            b1 = ^{
                lastSeekResult(lastSeekTime,
                               SGECreateError(SGErrorCodePacketOutputCancelSeek,
                                              SGOperationCodePacketOutputSeek));
            };
        }
        self->_seek_time = time;
        self->_seek_result = [result copy];
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
            if (self->_state == SGPacketOutputStateNone ||
                self->_state == SGPacketOutputStateClosed ||
                self->_state == SGPacketOutputStateFailed) {
                [self->_lock unlock];
                break;
            } else if (self->_state == SGPacketOutputStateOpening) {
                [self->_lock unlock];
                NSError *error = [self->_demuxable open];
                [self->_lock lock];
                self->_error = error;
                SGBlock b1 = [self setState:error ? SGPacketOutputStateFailed : SGPacketOutputStateOpened];
                [self->_lock unlock];
                b1();
                continue;
            } else if (self->_state == SGPacketOutputStateOpened ||
                       self->_state == SGPacketOutputStatePaused ||
                       self->_state == SGPacketOutputStateFinished) {
                [self->_wakeup lock];
                [self->_lock unlock];
                [self->_wakeup wait];
                [self->_wakeup unlock];
                continue;
            } else if (self->_state == SGPacketOutputStateSeeking) {
                self->_seeking_time = self->_seek_time;
                CMTime seeking_time = self->_seeking_time;
                [self->_lock unlock];
                NSError *error = [self->_demuxable seekToTime:seeking_time];
                [self->_lock lock];
                if (self->_state == SGPacketOutputStateSeeking &&
                    CMTimeCompare(self->_seek_time, seeking_time) != 0) {
                    [self->_lock unlock];
                    continue;
                }
                SGBlock b1 = ^{}, b2 = ^{};
                if (self->_seek_result) {
                    CMTime seekTime = self->_seek_time;
                    SGSeekResult seek_result = self->_seek_result;
                    b1 = ^{
                        seek_result(seekTime, error);
                    };
                }
                b2 = [self setState:SGPacketOutputStateReading];
                self->_seek_time = kCMTimeZero;
                self->_seeking_time = kCMTimeZero;
                self->_seek_result = nil;
                [self->_lock unlock];
                b1(); b2();
                continue;
            } else if (self->_state == SGPacketOutputStateReading) {
                [self->_lock unlock];
                SGPacket *packet = nil;
                NSError *error = [self->_demuxable nextPacket:&packet];
                if (error) {
                    [self->_lock lock];
                    SGBlock b1 = ^{};
                    if (self->_state == SGPacketOutputStateReading) {
                        b1 = [self setState:SGPacketOutputStateFinished];
                    }
                    [self->_lock unlock];
                    b1();
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

#pragma mark - SGPacketReaderDelegate

- (BOOL)demuxableShouldAbortBlockingFunctions:(id<SGDemuxable>)demuxable
{
    return SGLockCondEXE00(self->_lock, ^BOOL {
        switch (self->_state) {
            case SGPacketOutputStateFinished:
            case SGPacketOutputStateClosed:
            case SGPacketOutputStateFailed:
                return YES;
            case SGPacketOutputStateSeeking:
                return CMTimeCompare(self->_seek_time, self->_seeking_time) != 0;
            default:
                return NO;
        }
    }, nil);
}

@end
