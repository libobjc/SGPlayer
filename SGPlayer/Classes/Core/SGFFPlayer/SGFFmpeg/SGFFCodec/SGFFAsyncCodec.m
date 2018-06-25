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

@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSInvocationOperation * decodeOperation;
@property (nonatomic, strong) NSCondition * decodeCondition;

@end

@implementation SGFFAsyncCodec

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
    }
    return self;
}

- (BOOL)open
{
    self.state = SGFFCodecStateOpening;
    _packetQueue = [[SGFFObjectQueue alloc] init];
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;
    self.operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    self.decodeOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeThread) object:nil];
    self.decodeOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.decodeOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.operationQueue addOperation:self.decodeOperation];
    
    return YES;
}

- (void)pause
{
    if (self.state == SGFFCodecStateDecoding)
    {
        self.state = SGFFCodecStatePaused;
    }
}

- (void)resume
{
    if (self.state == SGFFCodecStatePaused)
    {
        self.state = SGFFCodecStateDecoding;
        [self.decodeCondition lock];
        [self.decodeCondition broadcast];
        [self.decodeCondition unlock];
    }
}

- (void)flush
{
    [self.packetQueue flush];
    [self.packetQueue putObjectSync:flushPacket];
    [self.decodeCondition lock];
    [self.decodeCondition broadcast];
    [self.decodeCondition unlock];
    [self.delegate codecDidChangeCapacity:self];
}

- (void)close
{
    self.state = SGFFCodecStateClosed;
    [self.packetQueue destroy];
    [self.decodeCondition lock];
    [self.decodeCondition broadcast];
    [self.decodeCondition unlock];
    [self.operationQueue cancelAllOperations];
    [self.operationQueue waitUntilAllOperationsAreFinished];
}

- (BOOL)putPacket:(SGFFPacket *)packet
{
    [self.packetQueue putObjectSync:packet];
    [self.delegate codecDidChangeCapacity:self];
    return YES;
}

- (NSUInteger)count
{
    return self.packetQueue.count;
}

- (CMTime)duration
{
    return self.packetQueue.duration;
}

- (long long)size
{
    return self.packetQueue.size;
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
        else if (self.state == SGFFCodecStatePaused)
        {
            [self.decodeCondition lock];
            if (self.state == SGFFCodecStatePaused)
            {
                [self.decodeCondition wait];
            }
            [self.decodeCondition unlock];
            continue;
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
                            [self.delegate codec:self hasNewFrame:frame];
                            [frame unlock];
                        }
                    }
                    [packet unlock];
                }
                [self.delegate codecDidChangeCapacity:self];
            }
            continue;
        }
    }
}

- (void)doFlushCodec
{
    
}

- (NSArray <id<SGFFFrame>> *)doDecode:(SGFFPacket *)packet error:(NSError * __autoreleasing *)error
{
    return nil;
}

@end
