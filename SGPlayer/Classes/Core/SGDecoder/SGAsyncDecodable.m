//
//  SGAsyncDecodable.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAsyncDecodable.h"
#import "SGObjectQueue.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGAsyncDecodable ()

{
    NSLock *_lock;
    NSCondition *_wakeup;
    SGCapacity *_capacity;
    Class _decodableClass;
    SGAsyncDecodableState _state;
    NSOperationQueue *_operationQueue;
    NSMutableDictionary<NSNumber *, NSValue *> *_timeStamps;
    NSMutableDictionary<NSNumber *, id<SGDecodable>> *_decodables;
    NSMutableDictionary<NSNumber *, SGObjectQueue *> *_packetQueues;
}

@end

@implementation SGAsyncDecodable

static SGPacket *gFlushPacket;
static SGPacket *gFinishPacket;

- (instancetype)initWithDecodableClass:(Class)decodableClass
{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            gFlushPacket = [[SGPacket alloc] init];
            [gFlushPacket lock];
            gFinishPacket = [[SGPacket alloc] init];
            [gFinishPacket lock];
        });
        self->_decodableClass = decodableClass;
        self->_lock = [[NSLock alloc] init];
        self->_timeStamps = [[NSMutableDictionary alloc] init];
        self->_decodables = [[NSMutableDictionary alloc] init];
        self->_packetQueues = [[NSMutableDictionary alloc] init];
        self->_wakeup = [[NSCondition alloc] init];
        self->_operationQueue = [[NSOperationQueue alloc] init];
        self->_operationQueue.maxConcurrentOperationCount = 1;
        self->_operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    return self;
}

- (void)dealloc
{
    SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_state != SGAsyncDecodableStateClosed;
    }, ^SGBlock {
        [self setState:SGAsyncDecodableStateClosed];
        for (SGObjectQueue *obj in self->_packetQueues.allValues) {
            [obj destroy];
        }
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
        return nil;
    });
}

#pragma mark - Setter & Getter

- (SGBlock)setState:(SGAsyncDecodableState)state
{
    if (_state == state) {
        return ^{};
    }
    SGAsyncDecodableState previous = _state;
    _state = state;
    if (previous == SGAsyncDecodableStatePaused ||
        previous == SGAsyncDecodableStateStalled) {
        [self->_wakeup lock];
        [self->_wakeup broadcast];
        [self->_wakeup unlock];
    }
    return ^{
        [self->_delegate decoder:self didChangeState:state];
    };
}

- (SGAsyncDecodableState)state
{
    __block SGAsyncDecodableState ret = SGAsyncDecodableStateNone;
    SGLockEXE00(self->_lock, ^{
        ret = self->_state;
    });
    return ret;
}

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state == SGAsyncDecodableStateNone;
    }, ^SGBlock {
        return [self setState:SGAsyncDecodableStateDecoding];
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
        return self->_state != SGAsyncDecodableStateClosed;
    }, ^SGBlock {
        return [self setState:SGAsyncDecodableStateClosed];
    }, ^BOOL(SGBlock block) {
        block();
        for (SGObjectQueue *obj in self->_packetQueues.allValues) {
            [obj destroy];
        }
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_state == SGAsyncDecodableStateDecoding;
    }, ^SGBlock {
        return [self setState:SGAsyncDecodableStatePaused];
    });
}

- (BOOL)resume
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_state == SGAsyncDecodableStatePaused;
    }, ^SGBlock {
        return [self setState:SGAsyncDecodableStateDecoding];
    });
}

- (BOOL)flush
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_state != SGAsyncDecodableStateClosed;
    }, ^SGBlock {
        for (SGObjectQueue *obj in self->_packetQueues.allValues) {
            [obj flush];
            [obj putObjectSync:gFlushPacket];
        }
        [self->_timeStamps removeAllObjects];
        SGBlock b1 = ^{};
        if (self->_state == SGAsyncDecodableStateStalled) {
            b1 = [self setState:SGAsyncDecodableStateDecoding];
        }
        return ^{
            b1();
            [self callbackForCapacity];
        };
    });
}

- (BOOL)finish:(NSArray<SGTrack *> *)tracks
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_state != SGAsyncDecodableStateClosed;
    }, ^SGBlock {
        for (SGTrack *obj in tracks) {
            [self->_packetQueues[@(obj.index)] putObjectAsync:gFinishPacket];
        }
        SGBlock b1 = ^{};
        if (self->_state == SGAsyncDecodableStateStalled) {
            b1 = [self setState:SGAsyncDecodableStateDecoding];
        }
        return ^{
            b1();
            [self callbackForCapacity];
        };
    });
}

- (BOOL)putPacket:(SGPacket *)packet
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_state != SGAsyncDecodableStateClosed;
    }, ^SGBlock {
        SGObjectQueue *queue = [self->_packetQueues objectForKey:@(packet.track.index)];
        if (!queue) {
            queue = [[SGObjectQueue alloc] init];
            [self->_decodables setObject:[[self->_decodableClass alloc] init] forKey:@(packet.track.index)];
            [self->_packetQueues setObject:queue forKey:@(packet.track.index)];
        }
        [queue putObjectSync:packet];
        SGBlock b1 = ^{};
        if (self->_state == SGAsyncDecodableStateStalled) {
            b1 = [self setState:SGAsyncDecodableStateDecoding];
        }
        return ^{
            b1();
            [self callbackForCapacity];
        };
    });
}

#pragma mark - Thread

- (void)runningThread
{
    while (YES) {
        @autoreleasepool {
            [self->_lock lock];
            if (self->_state == SGAsyncDecodableStateNone ||
                self->_state == SGAsyncDecodableStateClosed) {
                [self->_lock unlock];
                break;
            } else if (self->_state == SGAsyncDecodableStatePaused ||
                       self->_state == SGAsyncDecodableStateStalled) {
                [self->_wakeup lock];
                [self->_lock unlock];
                [self->_wakeup wait];
                [self->_wakeup unlock];
                continue;
            } else if (self->_state == SGAsyncDecodableStateDecoding) {
                NSNumber *index = nil;
                CMTime minimum = kCMTimePositiveInfinity;
                for (NSNumber *key in self->_packetQueues.allKeys) {
                    SGObjectQueue *obj = [self->_packetQueues objectForKey:key];
                    if (obj.capacity.count == 0) {
                        continue;
                    }
                    NSValue *value = [self->_timeStamps objectForKey:key];
                    if (!value) {
                        index = key;
                        break;
                    }
                    CMTime dts = kCMTimeZero;
                    [value getValue:&dts];
                    if (CMTimeCompare(dts, minimum) < 0) {
                        minimum = dts;
                        index = key;
                        continue;
                    }
                }
                if (!index) {
                    self->_state = SGAsyncDecodableStateStalled;
                    [self->_lock unlock];
                    continue;
                }
                SGBlock b1 = ^{};
                SGObjectQueue *queue = [self->_packetQueues objectForKey:index];
                id<SGDecodable> decodable = [self->_decodables objectForKey:index];
                SGPacket *packet = nil;
                [queue getObjectAsync:&packet];
                NSAssert(packet, @"Invalid Packet.");
                if (packet == gFlushPacket) {
                    b1 = ^{
                        [decodable flush];
                    };
                } else if (packet == gFinishPacket) {
                    b1 = ^{
                        for (SGFrame *obj in [decodable finish]) {
                            [self->_delegate decoder:self didOutputFrame:obj];
                            [obj unlock];
                        }
                        [self->_delegate decoder:self didFinish:index.intValue];
                    };
                } else {
                    CMTime dts = packet.decodeTimeStamp;
                    [self->_timeStamps setObject:[NSValue value:&dts withObjCType:@encode(CMTime)] forKey:index];
                    b1 = ^{
                        for (SGFrame *obj in [decodable decode:packet]) {
                            [self->_delegate decoder:self didOutputFrame:obj];
                            [obj unlock];
                        }
                    };
                }
                [self->_lock unlock];
                b1();
                [self callbackForCapacity];
                [packet unlock];
                continue;
            }
        }
    }
}

#pragma mark - Callabck

- (void)callbackForCapacity
{
    __block SGCapacity *ret = [[SGCapacity alloc] init];
    SGLockCondEXE10(self->_lock, ^BOOL {
        for (SGObjectQueue *obj in self->_packetQueues.allValues) {
            [ret add:obj.capacity];
        }
        return ![self->_capacity isEqualToCapacity:ret];
    }, ^SGBlock {
        self->_capacity = [ret copy];
        return ^{
            [self->_delegate decoder:self didChangeCapacity:ret];
        };
    });
}

@end
