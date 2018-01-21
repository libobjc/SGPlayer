//
//  SGFFAsyncCodec.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAsyncCodec.h"

@interface SGFFAsyncCodec ()

@property (nonatomic, assign) SGFFCodecState state;

@property (nonatomic, strong) SGFFPacketQueue * packetQueue;
@property (nonatomic, strong) SGFFOutputRenderQueue * outputRenderQueue;

@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSInvocationOperation * decodeOperation;
@property (nonatomic, strong) NSCondition * decodeCondition;

@end

@implementation SGFFAsyncCodec

@synthesize capacityDelegate = _capacityDelegate;
@synthesize processingDelegate = _processingDelegate;

+ (SGFFCodecType)type {return SGFFCodecTypeUnknown;}

- (BOOL)open
{
    self.state = SGFFCodecStateOpening;
    self.packetQueue = [[SGFFPacketQueue alloc] init];
    self.outputRenderQueue = [[SGFFOutputRenderQueue alloc] initWithMaxCount:self.outputRenderQueueMaxCount];
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;
    self.operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    self.decodeOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeThread) object:nil];
    self.decodeOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.decodeOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.operationQueue addOperation:self.decodeOperation];
    
    return YES;
}

- (void)flush
{
    if (self.state == SGFFCodecStateDecoding)
    {
        [self.decodeCondition lock];
        self.state = SGFFCodecStateFlushing;
        [self.decodeCondition wait];
        [self.decodeCondition unlock];
    }
}

- (void)close
{
    self.state = SGFFCodecStateClosed;
    [self.packetQueue destroy];
    [self.outputRenderQueue destroy];
    [self.operationQueue cancelAllOperations];
    [self.operationQueue waitUntilAllOperationsAreFinished];
    [self.decodeCondition lock];
    [self.decodeCondition broadcast];
    [self.decodeCondition unlock];
}

- (BOOL)putPacket:(AVPacket)packet
{
    [self.packetQueue putPacket:packet];
    [self.capacityDelegate codecDidChangeCapacity:self];
    return YES;
}

- (id <SGFFOutputRender>)outputFecthRender:(id <SGFFOutput>)output
{
    id <SGFFOutputRender> outputRender = [self.outputRenderQueue getObjectAsync];
    if (outputRender)
    {
        [self.capacityDelegate codecDidChangeCapacity:self];
    }
    return outputRender;
}

- (void)decodeThread
{
    if (!self.decodeCondition)
    {
        self.decodeCondition = [[NSCondition alloc] init];
    }
    self.state = SGFFCodecStateDecoding;
    while (YES)
    {
        [self.decodeCondition lock];
        if (self.state == SGFFCodecStateClosed
            || self.state == SGFFCodecStateFailed)
        {
            [self.decodeCondition unlock];
            break;
        }
        else if (self.state == SGFFCodecStateFlushing)
        {
            [self doFlushCodec];
            self.state = SGFFCodecStateDecoding;
            [self.decodeCondition signal];
            [self.decodeCondition unlock];
            continue;
        }
        else if (self.state == SGFFCodecStateDecoding)
        {
            [self doDecode];
            [self.decodeCondition unlock];
            continue;
        }
        [self.decodeCondition unlock];
    }
}

- (void)doFlushCodec {}
- (void)doDecode {}
- (NSInteger)outputRenderQueueMaxCount {return 5;}

- (void)doProcessingFrame:(id <SGFFFrame>)frame
{
    if ([self.processingDelegate respondsToSelector:@selector(codec:processingFrame:)]
        && [self.processingDelegate respondsToSelector:@selector(codec:processingOutputRender:)])
    {
        id <SGFFFrame> newFrame = [self.processingDelegate codec:self processingFrame:frame];
        if (newFrame)
        {
            id <SGFFOutputRender> outputRender = [self.processingDelegate codec:self processingOutputRender:newFrame];
            if (outputRender)
            {
                [self.outputRenderQueue putObjectSync:outputRender];
            }
        }
    }
}

- (long long)duration {return self.packetQueue.duration + self.outputRenderQueue.duration;}
- (long long)size {return self.packetQueue.size + self.outputRenderQueue.size;}
- (double)durationForSeconds {return SGFFTimebaseConvertToSeconds(self.duration, self.timebase);}

@end
