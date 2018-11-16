//
//  SGAsyncDecoder.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAsyncDecoder.h"
#import "SGObjectQueue.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGAsyncDecoder () <SGObjectQueueDelegate>

{
    SGAsyncDecoderState _state;
}

@property (nonatomic, strong) id <SGDecodable> decodable;
@property (nonatomic, assign) BOOL waitingFlush;
@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) SGCapacity * capacity;
@property (nonatomic, strong) NSCondition * wakeup;
@property (nonatomic, strong) SGObjectQueue * packetQueue;
@property (nonatomic, strong) NSOperationQueue * operationQueue;

@end

@implementation SGAsyncDecoder

static SGPacket * finishPacket;
static SGPacket * flushPacket;

- (instancetype)initWithDecodable:(id <SGDecodable>)decodable
{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            finishPacket = [[SGPacket alloc] init];
            [finishPacket lock];
            flushPacket = [[SGPacket alloc] init];
            [flushPacket lock];
        });
        self.decodable = decodable;
        self.lock = [[NSLock alloc] init];
        self.packetQueue = [[SGObjectQueue alloc] init];
        self.packetQueue.delegate = self;
        self.wakeup = [[NSCondition alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    return self;
}

- (void)dealloc
{
    SGLockCondEXE10(self.lock, ^BOOL {
        return self->_state != SGAsyncDecoderStateClosed;
    }, ^SGBlock {
        [self setState:SGAsyncDecoderStateClosed];
        [self.packetQueue destroy];
        [self.operationQueue cancelAllOperations];
        [self.operationQueue waitUntilAllOperationsAreFinished];
        return nil;
    });
}

#pragma mark - Setter & Getter

- (SGBlock)setState:(SGAsyncDecoderState)state
{
    if (_state == state) {
        return ^{};
    }
    SGAsyncDecoderState previous = _state;
    _state = state;
    if (previous == SGAsyncDecoderStatePaused) {
        [self.wakeup lock];
        [self.wakeup broadcast];
        [self.wakeup unlock];
    }
    return ^{
        [self.delegate decoder:self didChangeState:state];
    };
}

- (SGAsyncDecoderState)state
{
    __block SGAsyncDecoderState ret = SGAsyncDecoderStateNone;
    SGLockEXE00(self.lock, ^{
        ret = self->_state;
    });
    return ret;
}

- (SGCapacity *)capacity
{
    __block SGCapacity * ret = nil;
    SGLockEXE00(self.lock, ^{
        ret = [self->_capacity copy];
    });
    return ret ? ret : [[SGCapacity alloc] init];
}

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state == SGAsyncDecoderStateNone;
    }, ^SGBlock {
        return [self setState:SGAsyncDecoderStateDecoding];
    }, ^BOOL(SGBlock block) {
        block();
        NSOperation * operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(runningThread) object:nil];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
        [self.operationQueue addOperation:operation];
        return YES;
    });
}

- (BOOL)close
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state != SGAsyncDecoderStateClosed;
    }, ^SGBlock {
        return [self setState:SGAsyncDecoderStateClosed];
    }, ^BOOL(SGBlock block) {
        block();
        [self.packetQueue destroy];
        [self.operationQueue cancelAllOperations];
        [self.operationQueue waitUntilAllOperationsAreFinished];
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE10(self.lock, ^BOOL {
        return self->_state == SGAsyncDecoderStateDecoding;
    }, ^SGBlock {
        return [self setState:SGAsyncDecoderStatePaused];
    });
}

- (BOOL)resume
{
    return SGLockCondEXE10(self.lock, ^BOOL {
        return self->_state == SGAsyncDecoderStatePaused;
    }, ^SGBlock {
        return [self setState:SGAsyncDecoderStateDecoding];
    });
}

- (BOOL)flush
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state != SGAsyncDecoderStateClosed;
    }, ^SGBlock {
        self.waitingFlush = YES;
        return nil;
    }, ^BOOL(SGBlock block) {
        block();
        [self.packetQueue flush];
        [self.packetQueue putObjectSync:flushPacket]();
        return YES;
    });
}

- (BOOL)finish
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state != SGAsyncDecoderStateClosed;
    }, ^SGBlock {
        return nil;
    }, ^BOOL(SGBlock block) {
        block();
        [self.packetQueue putObjectSync:finishPacket]();
        return YES;
    });
}

- (BOOL)putPacket:(SGPacket *)packet
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state != SGAsyncDecoderStateClosed;
    }, ^SGBlock {
        return nil;
    }, ^BOOL(SGBlock block) {
        block();
        [self.packetQueue putObjectSync:packet]();
        return YES;
    });
}

#pragma mark - Thread

- (void)runningThread
{
    while (YES) {
        @autoreleasepool {
            [self.lock lock];
            if (self->_state == SGAsyncDecoderStateNone ||
                self->_state == SGAsyncDecoderStateClosed) {
                [self.lock unlock];
                break;
            } else if (self->_state == SGAsyncDecoderStatePaused) {
                [self.wakeup lock];
                [self.lock unlock];
                [self.wakeup wait];
                [self.wakeup unlock];
                continue;
            } else if (self->_state == SGAsyncDecoderStateDecoding) {
                [self.lock unlock];
                SGPacket * packet = nil;
                SGBlock b1 = [self.packetQueue getObjectSync:&packet];
                if (packet == flushPacket) {
                    [self.lock lock];
                    self.waitingFlush = NO;
                    [self.lock unlock];
                    [self.decodable flush];
                } else if (packet) {
                    NSArray <SGFrame *> * frames = [self.decodable decode:packet != finishPacket ? packet : nil];
                    [self.lock lock];
                    BOOL drop = self.waitingFlush;
                    [self.lock unlock];
                    if (!drop) {
                        for (SGFrame * frame in frames) {
                            [self.delegate decoder:self didOutputFrame:frame];
                        }
                    }
                    for (SGFrame * frame in frames) {
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
    SGLockCondEXE11(self.lock, ^BOOL {
        return ![self->_capacity isEqualToCapacity:capacity];
    }, ^SGBlock {
        self.capacity = capacity;
        return nil;
    }, ^BOOL(SGBlock block) {
        [self.delegate decoder:self didChangeCapacity:[capacity copy]];
        return YES;
    });
}

@end
