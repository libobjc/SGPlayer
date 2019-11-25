//
//  SGDecodeLoop.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGDecodeLoop.h"
#import "SGDecodeContext.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGDecodeLoop ()

{
    struct {
        SGDecodeLoopState state;
    } _flags;
    SGCapacity _capacity;
}

@property (nonatomic, copy, readonly) Class decoderClass;
@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) NSCondition *wakeup;
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, SGDecodeContext *> *contexts;

@end

@implementation SGDecodeLoop

- (instancetype)initWithDecoderClass:(Class)decoderClass
{
    if (self = [super init]) {
        self->_decoderClass = decoderClass;
        self->_lock = [[NSLock alloc] init];
        self->_wakeup = [[NSCondition alloc] init];
        self->_capacity = SGCapacityCreate();
        self->_contexts = [[NSMutableDictionary alloc] init];
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
        [self->_contexts enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, SGDecodeContext *obj, BOOL *stop) {
            [obj destory];
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
    [self->_contexts enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, SGDecodeContext *obj, BOOL *stop) {
        capacity = SGCapacityMaximum(capacity, [obj capacity]);
    }];
    if (SGCapacityIsEqual(capacity, self->_capacity)) {
        return ^{};
    }
    self->_capacity = capacity;
    return ^{
        [self->_delegate decodeLoop:self didChangeCapacity:capacity];
    };
}

#pragma mark - Context

- (SGDecodeContext *)contextWithKey:(NSNumber *)key
{
    SGDecodeContext *context = self->_contexts[key];
    if (!context) {
        context = [[SGDecodeContext alloc] initWithDecoderClass:self->_decoderClass];
        context.options = self->_options;
        self->_contexts[key] = context;
    }
    return context;
}

- (SGDecodeContext *)currentDecodeContext
{
    SGDecodeContext *context = nil;
    CMTime minimum = kCMTimePositiveInfinity;
    for (NSNumber *key in self->_contexts) {
        SGDecodeContext *obj = self->_contexts[key];
        if ([obj capacity].count == 0) {
            continue;
        }
        CMTime dts = obj.decodeTimeStamp;
        if (!CMTIME_IS_NUMERIC(dts)) {
            context = obj;
            break;
        }
        if (CMTimeCompare(dts, minimum) < 0) {
            minimum = dts;
            context = obj;
            continue;
        }
    }
    return context;
}

- (SGDecodeContext *)currentPredecodeContext
{
    SGDecodeContext *context = nil;
    for (NSNumber *key in self->_contexts) {
        SGDecodeContext *obj = self->_contexts[key];
        if ([obj needsPredecode]) {
            context = obj;
            break;
        }
    }
    return context;
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
        return
        self->_flags.state != SGDecodeLoopStateNone &&
        self->_flags.state != SGDecodeLoopStateClosed;
    }, ^SGBlock {
        return [self setState:SGDecodeLoopStateClosed];
    }, ^BOOL(SGBlock block) {
        block();
        [self->_contexts enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, SGDecodeContext *obj, BOOL *stop) {
            [obj destory];
        }];
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state != SGDecodeLoopStateNone &&
        self->_flags.state == SGDecodeLoopStateDecoding;
    }, ^SGBlock {
        return [self setState:SGDecodeLoopStatePaused];
    });
}

- (BOOL)resume
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state != SGDecodeLoopStateNone &&
        self->_flags.state == SGDecodeLoopStatePaused;
    }, ^SGBlock {
        return [self setState:SGDecodeLoopStateDecoding];
    });
}

- (BOOL)flush
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state != SGDecodeLoopStateNone &&
        self->_flags.state != SGDecodeLoopStateClosed;
    }, ^SGBlock {
        [self->_contexts enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, SGDecodeContext *obj, BOOL *stop) {
            [obj setNeedsFlush];
        }];
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
        return
        self->_flags.state != SGDecodeLoopStateNone &&
        self->_flags.state != SGDecodeLoopStateClosed;
    }, ^SGBlock {
        for (SGTrack *obj in tracks) {
            SGDecodeContext *context = [self contextWithKey:@(obj.index)];
            [context markAsFinished];
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
        return
        self->_flags.state != SGDecodeLoopStateNone &&
        self->_flags.state != SGDecodeLoopStateClosed;
    }, ^SGBlock {
        SGDecodeContext *context = [self contextWithKey:@(packet.track.index)];
        [context putPacket:packet];
        SGBlock b1 = ^{};
        SGBlock b2 = [self setCapacityIfNeeded];
        if (self->_flags.state == SGDecodeLoopStatePaused && [context needsPredecode]) {
            [self->_wakeup lock];
            [self->_wakeup broadcast];
            [self->_wakeup unlock];
        } else if (self->_flags.state == SGDecodeLoopStateStalled) {
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
    SGBlock lock = ^{
        [self->_lock lock];
    };
    SGBlock unlock = ^{
        [self->_lock unlock];
    };
    while (YES) {
        @autoreleasepool {
            [self->_lock lock];
            if (self->_flags.state == SGDecodeLoopStateNone ||
                self->_flags.state == SGDecodeLoopStateClosed) {
                [self->_lock unlock];
                break;
            } else if (self->_flags.state == SGDecodeLoopStateStalled) {
                [self->_wakeup lock];
                [self->_lock unlock];
                [self->_wakeup wait];
                [self->_wakeup unlock];
                continue;
            } else if (self->_flags.state == SGDecodeLoopStatePaused) {
                SGDecodeContext *context = [self currentPredecodeContext];
                if (!context) {
                    [self->_wakeup lock];
                    [self->_lock unlock];
                    [self->_wakeup wait];
                    [self->_wakeup unlock];
                    continue;
                }
                [context predecode:lock unlock:unlock];
                [self->_lock unlock];
                [NSThread sleepForTimeInterval:0.001];
                continue;
            } else if (self->_flags.state == SGDecodeLoopStateDecoding) {
                SGDecodeContext *context = [self currentDecodeContext];
                if (!context) {
                    self->_flags.state = SGDecodeLoopStateStalled;
                    [self->_lock unlock];
                    continue;
                }
                NSArray *objs = [context decode:lock unlock:unlock];
                [self->_lock unlock];
                for (SGFrame *obj in objs) {
                    [self->_delegate decodeLoop:self didOutputFrame:obj];
                    [obj unlock];
                }
                [self->_lock lock];
                SGBlock b1 = [self setCapacityIfNeeded];
                [self->_lock unlock];
                b1();
                continue;
            }
        }
    }
}

@end
