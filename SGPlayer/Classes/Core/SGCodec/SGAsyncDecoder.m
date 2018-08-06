//
//  SGAsyncDecoder.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAsyncDecoder.h"

@interface SGAsyncDecoder ()

@property (nonatomic, assign) SGDecoderState state;
@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSInvocationOperation * decodeOperation;
@property (nonatomic, strong) NSCondition * pausedCondition;

@end

@implementation SGAsyncDecoder

@synthesize index = _index;
@synthesize timebase = _timebase;
@synthesize codecpar = _codecpar;
@synthesize delegate = _delegate;

static SGPacket * flushPacket;

- (SGMediaType)mediaType
{
    return SGMediaTypeUnknown;
}

- (instancetype)init
{
    if (self = [super init])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            flushPacket = [[SGPacket alloc] init];
        });
        _packetQueue = [[SGObjectQueue alloc] init];
    }
    return self;
}

#pragma mark - Setter/Getter

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

#pragma mark - Interface

- (BOOL)open
{
    if (self.state != SGDecoderStateNone)
    {
        return NO;
    }
    self.state = SGDecoderStateDecoding;
    [self startDecodeThread];
    return YES;
}

- (void)pause
{
    if (self.state != SGDecoderStateDecoding)
    {
        return;
    }
    self.state = SGDecoderStatePaused;
}

- (void)resume
{
    if (self.state != SGDecoderStatePaused)
    {
        return;
    }
    self.state = SGDecoderStateDecoding;
    [self.pausedCondition lock];
    [self.pausedCondition broadcast];
    [self.pausedCondition unlock];
}

- (void)close
{
    if (self.state == SGDecoderStateClosed)
    {
        return;
    }
    self.state = SGDecoderStateClosed;
    [self.packetQueue destroy];
    [self.pausedCondition lock];
    [self.pausedCondition broadcast];
    [self.pausedCondition unlock];
    [self.operationQueue cancelAllOperations];
    [self.operationQueue waitUntilAllOperationsAreFinished];
}

- (BOOL)putPacket:(SGPacket *)packet
{
    if (self.state == SGDecoderStateClosed)
    {
        return NO;
    }
    [self.packetQueue putObjectSync:packet];
    [self.delegate decoderDidChangeCapacity:self];
    return YES;
}

- (void)flush
{
    if (self.state == SGDecoderStateClosed)
    {
        return;
    }
    [self.packetQueue flush];
    [self.packetQueue putObjectSync:flushPacket];
    [self.pausedCondition lock];
    [self.pausedCondition broadcast];
    [self.pausedCondition unlock];
    [self.delegate decoderDidChangeCapacity:self];
}

#pragma mark - Decode

- (void)startDecodeThread
{
    if (!self.operationQueue)
    {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    if (!self.pausedCondition)
    {
        self.pausedCondition = [[NSCondition alloc] init];
    }
    self.decodeOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeThread) object:nil];
    self.decodeOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.decodeOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.operationQueue addOperation:self.decodeOperation];
}

- (void)decodeThread
{
    while (YES)
    {
        if (self.state == SGDecoderStateClosed)
        {
            break;
        }
        else if (self.state == SGDecoderStatePaused)
        {
            [self.pausedCondition lock];
            if (self.state == SGDecoderStatePaused)
            {
                [self.pausedCondition wait];
            }
            [self.pausedCondition unlock];
            continue;
        }
        else if (self.state == SGDecoderStateDecoding)
        {
            SGPacket * packet = [self.packetQueue getObjectSync];
            if (packet == flushPacket)
            {
                [self doFlush];
            }
            else if (packet)
            {
                NSArray <__kindof SGFrame *> * frames = [self doDecode:packet];
                for (__kindof SGFrame * frame in frames)
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

- (NSArray <__kindof SGFrame *> *)doDecode:(SGPacket *)packet
{
    return nil;
}

@end
