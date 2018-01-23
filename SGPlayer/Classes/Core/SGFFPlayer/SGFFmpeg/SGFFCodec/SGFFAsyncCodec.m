//
//  SGFFAsyncCodec.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAsyncCodec.h"
#import "SGPlayerMacro.h"

@interface SGFFAsyncCodec ()

@property (nonatomic, assign) SGFFCodecState state;

@property (nonatomic, strong) SGFFObjectQueue * packetQueue;
@property (nonatomic, strong) SGFFObjectQueue * outputRenderQueue;

@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSInvocationOperation * decodeOperation;

@end

@implementation SGFFAsyncCodec

@synthesize capacityDelegate = _capacityDelegate;
@synthesize processingDelegate = _processingDelegate;

+ (SGFFCodecType)type {return SGFFCodecTypeUnknown;}

static SGFFPacket * flushPacket;

- (instancetype)init
{
    if (self = [super init])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            flushPacket = [[SGFFPacket alloc] init];
        });
    }
    return self;
}

- (BOOL)open
{
    self.state = SGFFCodecStateOpening;
    self.packetQueue = [[SGFFObjectQueue alloc] init];
    self.outputRenderQueue = [[SGFFObjectQueue alloc] initWithMaxCount:self.outputRenderQueueMaxCount];
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
    [self.packetQueue flush];
    [self.outputRenderQueue flush];
    [self.packetQueue putObjectSync:flushPacket];
    [self.capacityDelegate codecDidChangeCapacity:self];
}

- (void)close
{
    self.state = SGFFCodecStateClosed;
    [self.packetQueue destroy];
    [self.outputRenderQueue destroy];
    [self.operationQueue cancelAllOperations];
    [self.operationQueue waitUntilAllOperationsAreFinished];
}

- (BOOL)putPacket:(SGFFPacket *)packet
{
    [self.packetQueue putObjectSync:packet];
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
    self.state = SGFFCodecStateDecoding;
    while (YES)
    {
        if (self.state == SGFFCodecStateClosed
            || self.state == SGFFCodecStateFailed)
        {
            break;
        }
        else if (self.state == SGFFCodecStateDecoding)
        {
            SGFFPacket * packet = [self.packetQueue getObjectSync];
            if (packet == flushPacket)
            {
                [self doFlushCodec];
            }
            else if (packet)
            {
                @autoreleasepool
                {
                    NSError * error = nil;
                    NSArray <id <SGFFFrame>> * frames = [self doDecode:packet error:&error];
                    if (error)
                    {
                        SGPlayerLog(@"Decoder did Failed : %@", error);
                    }
                    else
                    {
                        for (id <SGFFFrame> frame in frames)
                        {
                            id <SGFFFrame> newFrame = [self.processingDelegate codec:self processingFrame:frame];
                            if (newFrame)
                            {
                                id <SGFFOutputRender> outputRender = [self.processingDelegate codec:self processingOutputRender:newFrame];
                                if (outputRender)
                                {
                                    [self.outputRenderQueue putObjectSync:outputRender];
                                    [outputRender unlock];
                                }
                                if (newFrame != frame)
                                {
                                    [newFrame unlock];
                                }
                            }
                            [frame unlock];
                        }
                    }
                    [packet unlock];
                }
            }
            continue;
        }
    }
}

- (void)doFlushCodec {}
- (NSArray <id<SGFFFrame>> *)doDecode:(SGFFPacket *)packet error:(NSError * __autoreleasing *)error {return nil;}
- (NSInteger)outputRenderQueueMaxCount {return 5;}
- (long long)duration {return self.packetQueue.duration + self.outputRenderQueue.duration;}
- (long long)size {return self.packetQueue.size + self.outputRenderQueue.size;}

@end
