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

@interface SGAsyncDecoder () <NSLocking>

{
    SGAsyncDecoderState _state;
}

@property (nonatomic, strong) id <SGDecodable> decodable;
@property (nonatomic, strong) SGObjectQueue * packetQueue;
@property (nonatomic, assign) BOOL waitingFlush;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSOperation * decodeOperation;
@property (nonatomic, strong) NSCondition * pausedCondition;

@end

@implementation SGAsyncDecoder

static SGPacket * flushPacket;

- (instancetype)initWithDecodable:(id <SGDecodable>)decodable
{
    if (self = [super init])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            flushPacket = [[SGPacket alloc] init];
            [flushPacket lock];
        });
        self.decodable = decodable;
        self.packetQueue = [[SGObjectQueue alloc] init];
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
    if (_state != state)
    {
        SGAsyncDecoderState previous = _state;
        _state = state;
        if (previous == SGAsyncDecoderStatePaused)
        {
            [self.pausedCondition lock];
            [self.pausedCondition broadcast];
            [self.pausedCondition unlock];
        }
        return ^{
            [self.delegate decoder:self didChangeState:state];
        };
    }
    return ^{};
}

- (SGAsyncDecoderState)state
{
    return _state;
}

- (BOOL)duratioin:(CMTime *)duration size:(int64_t *)size count:(NSUInteger *)count
{
    return [self.packetQueue duratioin:duration size:size count:count];
}

#pragma mark - Interface

- (BOOL)open
{
    [self lock];
    if (self.state != SGAsyncDecoderStateNone)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGAsyncDecoderStateDecoding];
    [self unlock];
    callback();
    [self startDecodeThread];
    return YES;
}

- (BOOL)close
{
    [self lock];
    if (self.state == SGAsyncDecoderStateClosed)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGAsyncDecoderStateClosed];
    [self unlock];
    callback();
    [self.packetQueue destroy];
    [self.operationQueue cancelAllOperations];
    [self.operationQueue waitUntilAllOperationsAreFinished];
    self.operationQueue = nil;
    self.decodeOperation = nil;
    return YES;
}

- (BOOL)pause
{
    [self lock];
    if (self.state != SGAsyncDecoderStateDecoding)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGAsyncDecoderStatePaused];
    [self unlock];
    callback();
    return YES;
}

- (BOOL)resume
{
    [self lock];
    if (self.state != SGAsyncDecoderStatePaused)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGAsyncDecoderStateDecoding];
    [self unlock];
    callback();
    return YES;
}

- (BOOL)putPacket:(SGPacket *)packet
{
    [self lock];
    if (self.state == SGAsyncDecoderStateClosed)
    {
        [self unlock];
        return NO;
    }
    [self unlock];
    [self.packetQueue putObjectSync:packet];
    [self callbackForCapacity];
    return YES;
}

- (BOOL)flush
{
    [self lock];
    if (self.state == SGAsyncDecoderStateClosed)
    {
        [self unlock];
        return NO;
    }
    [self unlock];
    [self.packetQueue flush];
    self.waitingFlush = YES;
    [self.packetQueue putObjectSync:flushPacket];
    [self callbackForCapacity];
    return YES;
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
    while (YES)
    {
        @autoreleasepool
        {
            [self lock];
            if (self.state == SGAsyncDecoderStateNone ||
                self.state == SGAsyncDecoderStateClosed)
            {
                [self unlock];
                break;
            }
            else if (self.state == SGAsyncDecoderStatePaused)
            {
                [self.pausedCondition lock];
                [self unlock];
                [self.pausedCondition wait];
                [self.pausedCondition unlock];
                continue;
            }
            else if (self.state == SGAsyncDecoderStateDecoding)
            {
                [self unlock];
                SGPacket * packet = [self.packetQueue getObjectSync];
                if (packet == flushPacket)
                {
                    [self.decodable flush];
                    self.waitingFlush = NO;
                }
                else if (packet)
                {
                    if (!self.waitingFlush)
                    {
                        NSArray <__kindof SGFrame *> * frames = [self.decodable decode:packet];
                        for (__kindof SGFrame * frame in frames)
                        {
                            if (!self.waitingFlush)
                            {
                                [self.delegate decoder:self didOutputFrame:frame];
                            }
                            [frame unlock];
                        }
                    }
                    [self callbackForCapacity];
                }
                [packet unlock];
                continue;
            }
        }
    }
}

#pragma mark - Callback

- (void)callbackForCapacity
{
    CMTime duration = kCMTimeZero;
    int64_t size = 0;
    NSUInteger count = 0;
    [self duratioin:&duration size:&size count:&count];
    [self.delegate decoder:self didChangeDuration:duration size:size count:count];
}

#pragma mark - NSLocking

- (void)lock
{
    if (!self.coreLock)
    {
        self.coreLock = [[NSLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
