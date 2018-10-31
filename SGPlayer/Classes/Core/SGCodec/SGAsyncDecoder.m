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
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) SGCapacity * capacity;
@property (nonatomic, strong) SGObjectQueue * packetQueue;
@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSOperation * decodeOperation;
@property (nonatomic, strong) NSCondition * pausedCondition;

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
        self.coreLock = [[NSLock alloc] init];
        self.packetQueue = [[SGObjectQueue alloc] init];
        self.packetQueue.delegate = self;
        self.pausedCondition = [[NSCondition alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    return self;
}

#pragma mark - Setter & Getter

- (SGBasicBlock)setState:(SGAsyncDecoderState)state
{
    if (_state == state) {
        return ^{};
    }
    SGAsyncDecoderState previous = _state;
    _state = state;
    if (previous == SGAsyncDecoderStatePaused) {
        [self.pausedCondition lock];
        [self.pausedCondition broadcast];
        [self.pausedCondition unlock];
    }
    return ^{
        [self.delegate decoder:self didChangeState:state];
    };
}

- (SGAsyncDecoderState)state
{
    __block SGAsyncDecoderState ret = SGAsyncDecoderStateNone;
    SGLockEXE00(self.coreLock, ^{
        ret = self->_state;
    });
    return ret;
}

- (SGCapacity *)capacity
{
    __block SGCapacity * ret = nil;
    SGLockEXE00(self.coreLock, ^{
        ret = [self->_capacity copy];
    });
    return ret ? ret : [[SGCapacity alloc] init];
}

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state == SGAsyncDecoderStateNone;
    }, ^SGBasicBlock {
        return [self setState:SGAsyncDecoderStateDecoding];
    }, ^BOOL(SGBasicBlock block) {
        block();
        [self startDecodeThread];
        return YES;
    });
}

- (BOOL)close
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state != SGAsyncDecoderStateClosed;
    }, ^SGBasicBlock {
        return [self setState:SGAsyncDecoderStateClosed];
    }, ^BOOL(SGBasicBlock block) {
        block();
        [self.packetQueue destroy]();
        [self.operationQueue cancelAllOperations];
        [self.operationQueue waitUntilAllOperationsAreFinished];
        self.operationQueue = nil;
        self.decodeOperation = nil;
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE10(self.coreLock, ^BOOL {
        return self->_state == SGAsyncDecoderStateDecoding;
    }, ^SGBasicBlock {
        return [self setState:SGAsyncDecoderStatePaused];
    });
}

- (BOOL)resume
{
    return SGLockCondEXE10(self.coreLock, ^BOOL {
        return self->_state == SGAsyncDecoderStatePaused;
    }, ^SGBasicBlock {
        return [self setState:SGAsyncDecoderStateDecoding];
    });
}

- (BOOL)putPacket:(SGPacket *)packet
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state != SGAsyncDecoderStateClosed;
    }, ^SGBasicBlock {
        return nil;
    }, ^BOOL(SGBasicBlock block) {
        block();
        [self.packetQueue putObjectSync:packet]();
        return YES;
    });
}

- (BOOL)finish
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state != SGAsyncDecoderStateClosed;
    }, ^SGBasicBlock {
        return nil;
    }, ^BOOL(SGBasicBlock block) {
        block();
        [self.packetQueue putObjectSync:finishPacket]();
        return YES;
    });
}

- (BOOL)flush
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state != SGAsyncDecoderStateClosed;
    }, ^SGBasicBlock {
        self.waitingFlush = YES;
        return nil;
    }, ^BOOL(SGBasicBlock block) {
        block();
        [self.packetQueue flush];
        [self.packetQueue putObjectSync:flushPacket]();
        return YES;
    });
}

#pragma mark - Decode

- (void)startDecodeThread
{
    SGWeakSelf
    self.decodeOperation = [NSBlockOperation blockOperationWithBlock:^{
        SGStrongSelf
        [self decodeThread];
    }];
    self.decodeOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.decodeOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    self.decodeOperation.name = [NSString stringWithFormat:@"%@-Decode-Queue", self.class];
    [self.operationQueue addOperation:self.decodeOperation];
}

- (void)decodeThread
{
    while (YES) {
        @autoreleasepool {
            [self.coreLock lock];
            if (self->_state == SGAsyncDecoderStateNone ||
                self->_state == SGAsyncDecoderStateClosed) {
                [self.coreLock unlock];
                break;
            } else if (self->_state == SGAsyncDecoderStatePaused) {
                [self.pausedCondition lock];
                [self.coreLock unlock];
                [self.pausedCondition wait];
                [self.pausedCondition unlock];
                continue;
            } else if (self->_state == SGAsyncDecoderStateDecoding) {
                [self.coreLock unlock];
                SGPacket * packet = nil;
                SGBasicBlock block = [self.packetQueue getObjectSync:&packet];
                if (packet == flushPacket) {
                    [self.coreLock lock];
                    self.waitingFlush = NO;
                    [self.coreLock unlock];
                    [self.decodable flush];
                } else if (packet) {
                    NSArray <SGFrame *> * frames = [self.decodable decode:packet != finishPacket ? packet : nil];
                    [self.coreLock lock];
                    BOOL drop = self.waitingFlush;
                    [self.coreLock unlock];
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
                block();
                continue;
            }
        }
    }
}

#pragma mark - SGObjectQueueDelegate

- (void)objectQueue:(SGObjectQueue *)objectQueue didChangeCapacity:(SGCapacity *)capacity
{
    capacity = [capacity copy];
    SGLockEXE00(self.coreLock, ^{
        self.capacity = capacity;
    });
    [self.delegate decoder:self didChangeCapacity:capacity];
}

@end
