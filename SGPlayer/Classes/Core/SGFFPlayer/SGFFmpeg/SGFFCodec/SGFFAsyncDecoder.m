//
//  SGFFAsyncDecoder.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAsyncDecoder.h"

@interface SGFFAsyncDecoder ()

@property (nonatomic, assign) SGFFDecoderState state;

@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSInvocationOperation * decodingOperation;
@property (nonatomic, strong) NSCondition * decodingCondition;

@end

@implementation SGFFAsyncDecoder

@synthesize index = _index;
@synthesize timebase = _timebase;
@synthesize codecpar = _codecpar;
@synthesize delegate = _delegate;

- (SGMediaType)mediaType
{
    return SGMediaTypeUnknown;
}

static SGFFPacket * flushPacket;

- (instancetype)init
{
    if (self = [super init])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            flushPacket = [[SGFFPacket alloc] init];
        });
        _packetQueue = [[SGFFObjectQueue alloc] init];
    }
    return self;
}

- (BOOL)startDecoding
{
    [self startDecodingThread];
    return YES;
}

- (void)pauseDecoding
{
    if (self.state == SGFFDecoderStateDecoding)
    {
        self.state = SGFFDecoderStatePaused;
    }
}

- (void)resumeDecoding
{
    if (self.state == SGFFDecoderStatePaused)
    {
        self.state = SGFFDecoderStateDecoding;
        [self.decodingCondition lock];
        [self.decodingCondition broadcast];
        [self.decodingCondition unlock];
    }
}

- (void)stopDecoding
{
    self.state = SGFFDecoderStateStoped;
    [self.packetQueue destroy];
    [self.decodingCondition lock];
    [self.decodingCondition broadcast];
    [self.decodingCondition unlock];
    [self.operationQueue cancelAllOperations];
    [self.operationQueue waitUntilAllOperationsAreFinished];
}

- (BOOL)putPacket:(SGFFPacket *)packet
{
    [self.packetQueue putObjectSync:packet];
    [self.delegate decoderDidChangeCapacity:self];
    return YES;
}

- (void)flush
{
    [self.packetQueue flush];
    [self.packetQueue putObjectSync:flushPacket];
    [self.decodingCondition lock];
    [self.decodingCondition broadcast];
    [self.decodingCondition unlock];
    [self.delegate decoderDidChangeCapacity:self];
}

- (CMTime)duration
{
    return self.packetQueue.duration;
}

- (long long)size
{
    return self.packetQueue.size;
}

- (NSUInteger)count
{
    return self.packetQueue.count;
}

- (void)startDecodingThread
{
    if (!self.operationQueue)
    {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    self.decodingOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodingThread) object:nil];
    self.decodingOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.decodingOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.operationQueue addOperation:self.decodingOperation];
}

- (void)decodingThread
{
    self.state = SGFFDecoderStateDecoding;
    while (YES)
    {
        if (self.state == SGFFDecoderStateStoped)
        {
            break;
        }
        else if (self.state == SGFFDecoderStatePaused)
        {
            [self.decodingCondition lock];
            if (self.state == SGFFDecoderStatePaused)
            {
                [self.decodingCondition wait];
            }
            [self.decodingCondition unlock];
            continue;
        }
        else if (self.state == SGFFDecoderStateDecoding)
        {
            SGFFPacket * packet = [self.packetQueue getObjectSync];
            if (packet == flushPacket)
            {
                [self doFlush];
            }
            else if (packet)
            {
                NSArray <id <SGFFFrame>> * frames = [self doDecode:packet];
                for (id <SGFFFrame> frame in frames)
                {
                    [self.delegate decoder:self hasNewFrame:frame];
                    [frame unlock];
                }
                [packet unlock];
                [self.delegate decoderDidChangeCapacity:self];
            }
            continue;
        }
    }
}

- (void)doFlush
{
    
}

- (NSArray <id <SGFFFrame>> *)doDecode:(SGFFPacket *)packet
{
    return nil;
}

@end
