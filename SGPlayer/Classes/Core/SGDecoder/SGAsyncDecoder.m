//
//  SGAsyncDecoder.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAsyncDecoder.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGAsyncDecoder () <SGObjectQueueDelegate>

{
    NSLock *_lock;
    BOOL _shouldFlush;
    NSCondition *_wakeup;
    SGCapacity *_capacity;
    id<SGDecodable> _decodable;
    SGAsyncDecoderState _state;
    SGObjectQueue *_packetQueue;
    NSOperationQueue *_operationQueue;
}

@end

@implementation SGAsyncDecoder

static SGPacket *gFlushPacket;
static SGPacket *gFinishPacket;

- (instancetype)initWithDecodable:(id<SGDecodable>)decodable
{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            gFlushPacket = [[SGPacket alloc] init];
            [gFlushPacket lock];
            gFinishPacket = [[SGPacket alloc] init];
            [gFinishPacket lock];
        });
        self->_decodable = decodable;
        self->_lock = [[NSLock alloc] init];
        self->_packetQueue = [[SGObjectQueue alloc] init];
        self->_packetQueue.delegate = self;
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
        return self->_state != SGAsyncDecoderStateClosed;
    }, ^SGBlock {
        [self setState:SGAsyncDecoderStateClosed];
        [self->_packetQueue destroy];
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
        return nil;
    });
}

#pragma mark - Setter & Getter

- (id<SGDecodable>)decodable
{
    return self->_decodable;
}

- (SGBlock)setState:(SGAsyncDecoderState)state
{
    if (_state == state) {
        return ^{};
    }
    SGAsyncDecoderState previous = _state;
    _state = state;
    if (previous == SGAsyncDecoderStatePaused) {
        [self->_wakeup lock];
        [self->_wakeup broadcast];
        [self->_wakeup unlock];
    }
    return ^{
        [self->_delegate decoder:self didChangeState:state];
    };
}

- (SGAsyncDecoderState)state
{
    __block SGAsyncDecoderState ret = SGAsyncDecoderStateNone;
    SGLockEXE00(self->_lock, ^{
        ret = self->_state;
    });
    return ret;
}

- (SGCapacity *)capacity
{
    __block SGCapacity *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_capacity copy];
    });
    return ret ? ret : [[SGCapacity alloc] init];
}

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state == SGAsyncDecoderStateNone;
    }, ^SGBlock {
        return [self setState:SGAsyncDecoderStateDecoding];
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
        return self->_state != SGAsyncDecoderStateClosed;
    }, ^SGBlock {
        return [self setState:SGAsyncDecoderStateClosed];
    }, ^BOOL(SGBlock block) {
        block();
        [self->_packetQueue destroy];
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_state == SGAsyncDecoderStateDecoding;
    }, ^SGBlock {
        return [self setState:SGAsyncDecoderStatePaused];
    });
}

- (BOOL)resume
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_state == SGAsyncDecoderStatePaused;
    }, ^SGBlock {
        return [self setState:SGAsyncDecoderStateDecoding];
    });
}

- (BOOL)flush
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state != SGAsyncDecoderStateClosed;
    }, ^SGBlock {
        self->_shouldFlush = YES;
        return nil;
    }, ^BOOL(SGBlock block) {
        block();
        [self->_packetQueue flush];
        [self->_packetQueue putObjectSync:gFlushPacket]();
        return YES;
    });
}

- (BOOL)finish
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state != SGAsyncDecoderStateClosed;
    }, ^SGBlock {
        return nil;
    }, ^BOOL(SGBlock block) {
        block();
        [self->_packetQueue putObjectSync:gFinishPacket]();
        return YES;
    });
}

- (BOOL)putPacket:(SGPacket *)packet
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state != SGAsyncDecoderStateClosed;
    }, ^SGBlock {
        return nil;
    }, ^BOOL(SGBlock block) {
        block();
        [self->_packetQueue putObjectSync:packet]();
        return YES;
    });
}

#pragma mark - Thread

- (void)runningThread
{
    while (YES) {
        @autoreleasepool {
            [self->_lock lock];
            if (self->_state == SGAsyncDecoderStateNone ||
                self->_state == SGAsyncDecoderStateClosed) {
                [self->_lock unlock];
                break;
            } else if (self->_state == SGAsyncDecoderStatePaused) {
                [self->_wakeup lock];
                [self->_lock unlock];
                [self->_wakeup wait];
                [self->_wakeup unlock];
                continue;
            } else if (self->_state == SGAsyncDecoderStateDecoding) {
                [self->_lock unlock];
                SGPacket *packet = nil;
                SGBlock b1 = [self->_packetQueue getObjectSync:&packet];
                if (packet == gFlushPacket) {
                    [self->_lock lock];
                    self->_shouldFlush = NO;
                    [self->_lock unlock];
                    [self->_decodable flush];
                } else if (packet) {
                    NSArray<SGFrame *> *frames = [self->_decodable decode:packet != gFinishPacket ? packet : nil];
                    [self->_lock lock];
                    BOOL drop = self->_shouldFlush;
                    [self->_lock unlock];
                    if (!drop) {
                        for (SGFrame *frame in frames) {
                            [self->_delegate decoder:self didOutputFrame:frame];
                        }
                    }
                    for (SGFrame *frame in frames) {
                        [frame unlock];
                    }
                }
                [packet unlock];
                b1();
                continue;
            }
        }
    }
}

#pragma mark - SGObjectQueueDelegate

- (void)objectQueue:(SGObjectQueue *)objectQueue didChangeCapacity:(SGCapacity *)capacity
{
    [capacity copy];
    SGLockCondEXE11(self->_lock, ^BOOL {
        return ![self->_capacity isEqualToCapacity:capacity];
    }, ^SGBlock {
        self->_capacity = capacity;
        return nil;
    }, ^BOOL(SGBlock block) {
        [self->_delegate decoder:self didChangeCapacity:[capacity copy]];
        return YES;
    });
}

@end
