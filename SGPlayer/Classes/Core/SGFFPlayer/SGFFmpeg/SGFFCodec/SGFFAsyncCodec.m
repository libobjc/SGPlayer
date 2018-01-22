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

@property (nonatomic, strong) SGFFPacketQueue * packetQueue;
@property (nonatomic, strong) SGFFOutputRenderQueue * outputRenderQueue;

@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSInvocationOperation * decodeOperation;

@end

@implementation SGFFAsyncCodec

@synthesize capacityDelegate = _capacityDelegate;
@synthesize processingDelegate = _processingDelegate;

+ (SGFFCodecType)type {return SGFFCodecTypeUnknown;}

static AVPacket flushPacket;

- (instancetype)init
{
    if (self = [super init])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            av_init_packet(&flushPacket);
            flushPacket.data = (uint8_t *)&flushPacket;
            flushPacket.duration = 0;
        });
    }
    return self;
}

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
    [self.packetQueue flush];
    [self.outputRenderQueue flush];
    [self.packetQueue putPacket:flushPacket];
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
            AVPacket packet = [self.packetQueue getPacketSync];
            if (packet.data == flushPacket.data)
            {
                [self doFlushCodec];
            }
            else if (packet.data)
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
                                }
                            }
                            [frame unlock];
                        }
                    }
                }
            }
            av_packet_unref(&packet);
            continue;
        }
    }
}

- (void)doFlushCodec {}
- (NSArray <id<SGFFFrame>> *)doDecode:(AVPacket)packet error:(NSError * __autoreleasing *)error {return nil;}
- (NSInteger)outputRenderQueueMaxCount {return 5;}
- (long long)duration {return self.packetQueue.duration + self.outputRenderQueue.duration;}
- (long long)size {return self.packetQueue.size + self.outputRenderQueue.size;}

@end
