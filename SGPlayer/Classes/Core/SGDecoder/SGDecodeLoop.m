//
//  SGDecodeLoop.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGDecodeLoop.h"
#import "SGObjectQueue.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGDecodeLoop ()

{
    struct {
        SGDecodeLoopState state;
    } _flags;
    SGCapacity _capacity;
}

@property (nonatomic, copy, readonly) Class decodableClass;
@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) NSCondition *wakeup;
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, NSValue *> *timeStamps;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, NSNumber *> *flushFlags;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, id<SGDecodable>> *decodables;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, SGObjectQueue *> *packetQueues;

@end

@implementation SGDecodeLoop

static SGPacket *gFlushPacket = nil;
static SGPacket *gFinishPacket = nil;

- (instancetype)initWithDecodableClass:(Class)decodableClass
{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            gFlushPacket = [[SGPacket alloc] init];
            gFinishPacket = [[SGPacket alloc] init];
            [gFlushPacket lock];
            [gFinishPacket lock];
        });
        self->_decodableClass = decodableClass;
        self->_lock = [[NSLock alloc] init];
        self->_wakeup = [[NSCondition alloc] init];
        self->_capacity = SGCapacityCreate();
        self->_timeStamps = [[NSMutableDictionary alloc] init];
        self->_flushFlags = [[NSMutableDictionary alloc] init];
        self->_decodables = [[NSMutableDictionary alloc] init];
        self->_packetQueues = [[NSMutableDictionary alloc] init];
        self->_operationQueue = [[NSOperationQueue alloc] init];
        self->_operationQueue.maxConcurrentOperationCount = 1;
        self->_operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    return self;
}

- (void)dealloc
{
    SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.state != SGDecodeLoopStateClosed;
    }, ^SGBlock {
        [self setState:SGDecodeLoopStateClosed];
        [self->_packetQueues enumerateKeysAndObjectsUsingBlock:^(id key, SGObjectQueue *obj, BOOL *stop) {
            [obj destroy];
        }];
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
        return nil;
    });
}

#pragma mark - Setter & Getter

- (SGBlock)setState:(SGDecodeLoopState)state
{
    if (self->_flags.state == state) {
        return ^{};
    }
    SGDecodeLoopState previous = self->_flags.state;
    self->_flags.state = state;
    if (previous == SGDecodeLoopStatePaused ||
        previous == SGDecodeLoopStateStalled) {
        [self->_wakeup lock];
        [self->_wakeup broadcast];
        [self->_wakeup unlock];
    }
    return ^{
        [self->_delegate decodeLoop:self didChangeState:state];
    };
}

- (SGDecodeLoopState)state
{
    __block SGDecodeLoopState ret = SGDecodeLoopStateNone;
    SGLockEXE00(self->_lock, ^{
        ret = self->_flags.state;
    });
    return ret;
}

- (SGBlock)setCapacityIfNeeded
{
    __block SGCapacity capacity = SGCapacityCreate();
    [self->_packetQueues enumerateKeysAndObjectsUsingBlock:^(id key, SGObjectQueue *obj, BOOL *stop) {
        capacity = SGCapacityMaximum(capacity, obj.capacity);
    }];
    if (SGCapacityIsEqual(capacity, self->_capacity)) {
        return ^{};
    }
    self->_capacity = capacity;
    return ^{
        [self->_delegate decodeLoop:self didChangeCapacity:capacity];
    };
}

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == SGDecodeLoopStateNone;
    }, ^SGBlock {
        return [self setState:SGDecodeLoopStateDecoding];
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
        return self->_flags.state != SGDecodeLoopStateClosed;
    }, ^SGBlock {
        return [self setState:SGDecodeLoopStateClosed];
    }, ^BOOL(SGBlock block) {
        block();
        [self->_packetQueues enumerateKeysAndObjectsUsingBlock:^(id key, SGObjectQueue *obj, BOOL *stop) {
            [obj destroy];
        }];
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.state == SGDecodeLoopStateDecoding;
    }, ^SGBlock {
        return [self setState:SGDecodeLoopStatePaused];
    });
}

- (BOOL)resume
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.state == SGDecodeLoopStatePaused;
    }, ^SGBlock {
        return [self setState:SGDecodeLoopStateDecoding];
    });
}

- (BOOL)flush
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.state != SGDecodeLoopStateClosed;
    }, ^SGBlock {
        [self->_packetQueues enumerateKeysAndObjectsUsingBlock:^(id key, SGObjectQueue *obj, BOOL *stop) {
            [obj flush];
            [obj putObjectSync:gFlushPacket];
            self->_flushFlags[key] = @(YES);
        }];
        [self->_timeStamps removeAllObjects];
        SGBlock b1 = ^{};
        SGBlock b2 = [self setCapacityIfNeeded];
        if (self->_flags.state == SGDecodeLoopStateStalled) {
            b1 = [self setState:SGDecodeLoopStateDecoding];
        }
        return ^{
            b1(); b2();
        };
    });
}

- (BOOL)finish:(NSArray<SGTrack *> *)tracks
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.state != SGDecodeLoopStateClosed;
    }, ^SGBlock {
        for (SGTrack *obj in tracks) {
            [self->_packetQueues[@(obj.index)] putObjectSync:gFinishPacket];
        }
        SGBlock b1 = ^{};
        SGBlock b2 = [self setCapacityIfNeeded];
        if (self->_flags.state == SGDecodeLoopStateStalled) {
            b1 = [self setState:SGDecodeLoopStateDecoding];
        }
        return ^{
            b1(); b2();
        };
    });
}

- (BOOL)putPacket:(SGPacket *)packet
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.state != SGDecodeLoopStateClosed;
    }, ^SGBlock {
        SGObjectQueue *queue = self->_packetQueues[@(packet.track.index)];
        if (!queue) {
            queue = [[SGObjectQueue alloc] init];
            id<SGDecodable> obj = [[self->_decodableClass alloc] init];
            obj.options = self->_options;
            [self->_decodables setObject:obj forKey:@(packet.track.index)];
            [self->_packetQueues setObject:queue forKey:@(packet.track.index)];
        }
        [queue putObjectSync:packet];
        SGBlock b1 = ^{};
        SGBlock b2 = [self setCapacityIfNeeded];
        if (self->_flags.state == SGDecodeLoopStateStalled) {
            b1 = [self setState:SGDecodeLoopStateDecoding];
        }
        return ^{
            b1(); b2();
        };
    });
}

#pragma mark - Thread

- (void)runningThread
{
    while (YES) {
        @autoreleasepool {
            [self->_lock lock];
            if (self->_flags.state == SGDecodeLoopStateNone ||
                self->_flags.state == SGDecodeLoopStateClosed) {
                [self->_lock unlock];
                break;
            } else if (self->_flags.state == SGDecodeLoopStatePaused ||
                       self->_flags.state == SGDecodeLoopStateStalled) {
                [self->_wakeup lock];
                [self->_lock unlock];
                [self->_wakeup wait];
                [self->_wakeup unlock];
                continue;
            } else if (self->_flags.state == SGDecodeLoopStateDecoding) {
                NSNumber *index = nil;
                CMTime minimum = kCMTimePositiveInfinity;
                for (NSNumber *key in self->_packetQueues) {
                    SGObjectQueue *obj = self->_packetQueues[key];
                    if (obj.capacity.count == 0) {
                        continue;
                    }
                    NSValue *value = self->_timeStamps[key];
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
                    self->_flags.state = SGDecodeLoopStateStalled;
                    [self->_lock unlock];
                    continue;
                }
                SGObjectQueue *queue = self->_packetQueues[index];
                id<SGDecodable> decodable = self->_decodables[index];
                SGPacket *packet = nil;
                [queue getObjectAsync:&packet];
                NSAssert(packet, @"Invalid Packet.");
                if (packet == gFlushPacket) {
                    self->_flushFlags[index] = @(NO);
                    [self->_lock unlock];
                    [decodable flush];
                    [self->_lock lock];
                } else {
                    NSArray *objs = nil;
                    if (packet == gFinishPacket) {
                        [self->_lock unlock];
                        objs = [decodable finish];
                    } else {
                        CMTime dts = packet.decodeTimeStamp;
                        [self->_timeStamps setObject:[NSValue value:&dts withObjCType:@encode(CMTime)] forKey:index];
                        [self->_lock unlock];
                        objs = [decodable decode:packet];
                    }
                    [self->_lock lock];
                    if (self->_flushFlags[index].boolValue) {
                        for (SGFrame *obj in objs) {
                            [obj unlock];
                        }
                    } else {
                        [self->_lock unlock];
                        for (SGFrame *obj in objs) {
                            [self->_delegate decodeLoop:self didOutputFrame:obj];
                            [obj unlock];
                        }
                        [self->_lock lock];
                    }
                }
                SGBlock b1 = [self setCapacityIfNeeded];
                [self->_lock unlock];
                [packet unlock];
                b1();
                continue;
            }
        }
    }
}

@end
