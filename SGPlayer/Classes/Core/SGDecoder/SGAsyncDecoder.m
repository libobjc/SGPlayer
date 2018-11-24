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
    uint32_t _is_waiting_flush;
    
    NSLock *_lock;
    NSCondition *_wakeup;
    SGCapacity *_capacity;
    id<SGDecodable> _decodable;
    SGAsyncDecoderState _state;
    SGObjectQueue *_packet_queue;
    NSOperationQueue *_operation_queue;
}

@end

@implementation SGAsyncDecoder

static SGPacket *finishPacket;
static SGPacket *flushPacket;

- (instancetype)initWithDecodable:(id<SGDecodable>)decodable
{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            finishPacket = [[SGPacket alloc] init];
            [finishPacket lock];
            flushPacket = [[SGPacket alloc] init];
            [flushPacket lock];
        });
        self->_decodable = decodable;
        self->_lock = [[NSLock alloc] init];
        self->_packet_queue = [[SGObjectQueue alloc] init];
        self->_packet_queue.delegate = self;
        self->_wakeup = [[NSCondition alloc] init];
        self->_operation_queue = [[NSOperationQueue alloc] init];
        self->_operation_queue.maxConcurrentOperationCount = 1;
        self->_operation_queue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    return self;
}

- (void)dealloc
{
    SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_state != SGAsyncDecoderStateClosed;
    }, ^SGBlock {
        [self setState:SGAsyncDecoderStateClosed];
        [self->_packet_queue destroy];
        [self->_operation_queue cancelAllOperations];
        [self->_operation_queue waitUntilAllOperationsAreFinished];
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
        self->_operation_queue = [[NSOperationQueue alloc] init];
        self->_operation_queue.qualityOfService = NSQualityOfServiceUserInteractive;
        [self->_operation_queue addOperation:operation];
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
        [self->_packet_queue destroy];
        [self->_operation_queue cancelAllOperations];
        [self->_operation_queue waitUntilAllOperationsAreFinished];
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
        self->_is_waiting_flush = 1;
        return nil;
    }, ^BOOL(SGBlock block) {
        block();
        [self->_packet_queue flush];
        [self->_packet_queue putObjectSync:flushPacket]();
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
        [self->_packet_queue putObjectSync:finishPacket]();
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
        [self->_packet_queue putObjectSync:packet]();
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
                SGBlock b1 = [self->_packet_queue getObjectSync:&packet];
                if (packet == flushPacket) {
                    [self->_lock lock];
                    self->_is_waiting_flush = 0;
                    [self->_lock unlock];
                    [self->_decodable flush];
                } else if (packet) {
                    NSArray<SGFrame *> *frames = [self->_decodable decode:packet != finishPacket ? packet : nil];
                    [self->_lock lock];
                    BOOL drop = self->_is_waiting_flush;
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
