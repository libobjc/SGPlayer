//
//  SGFFAsyncCodec.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAsyncCodec.h"

@interface SGFFAsyncCodec ()

@property (nonatomic, strong) SGFFPacketQueue * packetQueue;
@property (nonatomic, strong) SGFFOutputRenderQueue * outputRenderQueue;

@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSInvocationOperation * decodeOperation;

@end

@implementation SGFFAsyncCodec

@synthesize processingDelegate = _processingDelegate;

+ (SGFFCodecType)type
{
    return SGFFCodecTypeUnknown;
}

- (BOOL)open
{
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

- (void)close
{
    
}

- (void)putPacket:(AVPacket)packet
{
    [self.packetQueue putPacket:packet];
}

- (void)decodeThread {}
- (NSInteger)outputRenderQueueMaxCount {return 5;}

- (long long)duration {return self.packetQueue.duration + self.outputRenderQueue.duration;}
- (long long)size {return self.packetQueue.size + self.outputRenderQueue.size;}

@end
