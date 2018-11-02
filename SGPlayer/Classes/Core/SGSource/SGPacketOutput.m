//
//  SGURLSource.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPacketOutput.h"
#import "SGAsset+Internal.h"
#import "SGPacket+Internal.h"
#import "SGError.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGPacketOutput () <SGPacketReadableDelegate>

{
    SGPacketOutputState _state;
}

@property (nonatomic, strong) SGAsset * asset;
@property (nonatomic, strong) id <SGPacketReadable> readable;
@property (nonatomic, strong) NSError * error;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSOperation * openOperation;
@property (nonatomic, strong) NSOperation * readOperation;
@property (nonatomic, strong) NSCondition * pausedCondition;
@property (nonatomic, assign) CMTime seekTimeStamp;
@property (nonatomic, assign) CMTime seekingTimeStamp;
@property (nonatomic, copy) SGSeekResultBlock seekResult;

@end

@implementation SGPacketOutput

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self.asset = asset;
        self.readable = [self.asset newReadable];
        self.coreLock = [[NSLock alloc] init];
        self.pausedCondition = [[NSCondition alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    return self;
}

#pragma mark - Mapping

SGGet0Map(CMTime, duration, self.readable)
SGGet0Map(NSDictionary *, metadata, self.readable)
SGGet0Map(NSArray <SGTrack *> *, tracks, self.readable)
SGGet0Map(NSArray <SGTrack *> *, audioTracks, self.readable)
SGGet0Map(NSArray <SGTrack *> *, videoTracks, self.readable)
SGGet0Map(NSArray <SGTrack *> *, otherTracks, self.readable)

#pragma mark - Setter & Getter

- (SGBlock)setState:(SGPacketOutputState)state
{
    if (_state == state) {
        return ^{};
    }
    SGPacketOutputState privious = _state;
    _state = state;
    if (privious == SGPacketOutputStatePaused) {
        [self.pausedCondition lock];
        [self.pausedCondition broadcast];
        [self.pausedCondition unlock];
    } else if (privious == SGPacketOutputStateOpened ||
               privious == SGPacketOutputStateFinished) {
        if (state == SGPacketOutputStateReading ||
            state == SGPacketOutputStateSeeking) {
            [self startReadThread];
        }
    }
    return ^{
        [self.delegate packetOutput:self didChangeState:state];
    };
}

- (SGPacketOutputState)state
{
    __block SGPacketOutputState ret = SGPacketOutputStateNone;
    SGLockEXE00(self.coreLock, ^{
        ret = self->_state;
    });
    return ret;
}

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state == SGPacketOutputStateNone;
    }, ^SGBlock {
        return [self setState:SGPacketOutputStateOpening];
    }, ^BOOL(SGBlock block) {
        block();
        [self startOpenThread];
        return YES;
    });
}

- (BOOL)start
{
    return [self resume];
}

- (BOOL)close
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state != SGPacketOutputStateClosed;
    }, ^SGBlock {
        return [self setState:SGPacketOutputStateClosed];
    }, ^BOOL(SGBlock block) {
        block();
        [self.operationQueue cancelAllOperations];
        [self.operationQueue waitUntilAllOperationsAreFinished];
        self.operationQueue = nil;
        self.openOperation = nil;
        self.readOperation = nil;
        [self.readable close];
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE10(self.coreLock, ^BOOL {
        return self->_state == SGPacketOutputStateReading || self->_state == SGPacketOutputStateSeeking;
    }, ^SGBlock {
        return [self setState:SGPacketOutputStatePaused];
    });
}

- (BOOL)resume
{
    return SGLockCondEXE10(self.coreLock, ^BOOL {
        return self->_state == SGPacketOutputStatePaused || self->_state == SGPacketOutputStateOpened;
    }, ^SGBlock {
        return [self setState:SGPacketOutputStateReading];
    });
}

#pragma mark - Seeking

- (BOOL)seekable
{
    return [self.readable seekable] == nil;
}

- (BOOL)seekToTime:(CMTime)time result:(SGSeekResultBlock)result
{
    if (![self seekable]) {
        return NO;
    }
    return SGLockCondEXE10(self.coreLock, ^BOOL {
        return self->_state == SGPacketOutputStateReading || self->_state == SGPacketOutputStatePaused || self->_state == SGPacketOutputStateSeeking || self->_state == SGPacketOutputStateFinished;
    }, ^SGBlock {
        self.seekTimeStamp = time;
        self.seekResult = result;
        return [self setState:SGPacketOutputStateSeeking];
    });
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
    self.error = [self.readable open];
    SGLockEXE10(self.coreLock, ^SGBlock {
        return [self setState:self.error ? SGPacketOutputStateFailed : SGPacketOutputStateOpened];
    });
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
    self.readOperation.name = [NSString stringWithFormat:@"%@-readQueue", self.class];
    [self.readOperation addDependency:self.openOperation];
    [self.operationQueue addOperation:self.readOperation];
}

- (void)readThread
{
    while (YES) {
        @autoreleasepool {
            [self.coreLock lock];
            if (self->_state == SGPacketOutputStateNone ||
                self->_state == SGPacketOutputStateFinished ||
                self->_state == SGPacketOutputStateClosed ||
                self->_state == SGPacketOutputStateFailed) {
                [self.coreLock unlock];
                break;
            } else if (self->_state == SGPacketOutputStatePaused) {
                [self.pausedCondition lock];
                [self.coreLock unlock];
                [self.pausedCondition wait];
                [self.pausedCondition unlock];
                continue;
            } else if (self->_state == SGPacketOutputStateSeeking) {
                self.seekingTimeStamp = self.seekTimeStamp;
                CMTime seekingTimeStamp = self.seekingTimeStamp;
                [self.coreLock unlock];
                NSError * error = [self.readable seekToTime:seekingTimeStamp];
                [self.coreLock lock];
                if (self->_state == SGPacketOutputStateSeeking &&
                    CMTimeCompare(self.seekTimeStamp, seekingTimeStamp) != 0) {
                    [self.coreLock unlock];
                    continue;
                }
                SGBlock callback = [self setState:SGPacketOutputStateReading];
                CMTime seekTimeStamp = self.seekTimeStamp;
                SGSeekResultBlock seekResult = self.seekResult;
                self.seekTimeStamp = kCMTimeZero;
                self.seekingTimeStamp = kCMTimeZero;
                self.seekResult = nil;
                [self.coreLock unlock];
                if (seekResult) {
                    seekResult(seekTimeStamp, error);
                }
                callback();
                continue;
            } else if (self->_state == SGPacketOutputStateReading) {
                [self.coreLock unlock];
                SGPacket * packet = [[SGObjectPool sharePool] objectWithClass:[SGPacket class]];
                NSError * error = [self.readable nextPacket:packet];
                if (error) {
                    [self.coreLock lock];
                    SGBlock callback = ^{};
                    if (self->_state == SGPacketOutputStateReading) {
                        callback = [self setState:SGPacketOutputStateFinished];
                    }
                    [self.coreLock unlock];
                    callback();
                } else {
                    for (SGTrack * obj in self.readable.tracks) {
                        if (obj.index == packet.core->stream_index) {
                            [packet configurateWithTrack:obj];
                            break;
                        }
                    }
                    [self.delegate packetOutput:self didOutputPacket:packet];
                }
                [packet unlock];
                continue;
            }
        }
    }
}

#pragma mark - SGPacketReaderDelegate

- (BOOL)packetReadableShouldAbortBlockingFunctions:(id <SGPacketReadable>)packetReadable
{
    return SGLockCondEXE00(self.coreLock, ^BOOL {
        switch (self->_state) {
            case SGPacketOutputStateFinished:
            case SGPacketOutputStateClosed:
            case SGPacketOutputStateFailed:
                return YES;
            case SGPacketOutputStateSeeking:
                return CMTimeCompare(self.seekTimeStamp, self.seekingTimeStamp) != 0;
            default:
                return NO;
        }
    }, nil);
}

@end
