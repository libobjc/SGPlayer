//
//  SGURLSource.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPacketOutput.h"
#import "SGAsset+Internal.h"
#import "SGPacket+Internal.h"
#import "SGError.h"
#import "SGMacro.h"

@interface SGPacketOutput () <NSLocking, SGPacketReadableDelegate>

{
    SGPacketOutputState _state;
}

@property (nonatomic, strong) SGAsset * asset;
@property (nonatomic, strong) id <SGPacketReadable> readable;
@property (nonatomic, assign) CMTime seekTimeStamp;
@property (nonatomic, assign) CMTime seekingTimeStamp;
@property (nonatomic, copy) void(^seekCompletionHandler)(CMTime, NSError *);
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSOperation * openOperation;
@property (nonatomic, strong) NSOperation * readOperation;
@property (nonatomic, strong) NSCondition * pausedCondition;

@end

@implementation SGPacketOutput

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init])
    {
        self.asset = asset;
        self.readable = [self.asset newReadable];
        self.pausedCondition = [[NSCondition alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    return self;
}

#pragma mark - Setter & Getter

- (SGBasicBlock)setState:(SGPacketOutputState)state
{
    if (_state != state)
    {
        SGPacketOutputState privious = _state;
        _state = state;
        if (privious == SGPacketOutputStatePaused)
        {
            [self.pausedCondition lock];
            [self.pausedCondition broadcast];
            [self.pausedCondition unlock];
        }
        else if (privious == SGPacketOutputStateOpened)
        {
            if (state == SGPacketOutputStateReading)
            {
                [self startReadThread];
            }
        }
        else if (privious == SGPacketOutputStateFinished)
        {
            if (state == SGPacketOutputStateSeeking)
            {
                [self startReadThread];
            }
        }
        return ^{
            [self.delegate packetOutput:self didChangeState:state];
        };
    }
    return ^{};
}

- (SGPacketOutputState)state
{
    return _state;
}

- (NSError *)error
{
    return self.readable.error;
}

- (CMTime)duration
{
    return self.readable.duration;
}

- (NSDictionary *)metadata
{
    return self.readable.metadata;
}

- (NSArray <SGStream *> *)streams
{
    return self.readable.streams;
}

- (NSArray <SGStream *> *)audioStreams
{
    return self.readable.audioStreams;
}

- (NSArray <SGStream *> *)videoStreams
{
    return self.readable.videoStreams;
}

- (NSArray <SGStream *> *)otherStreams
{
    return self.readable.otherStreams;
}

#pragma mark - Interface

- (NSError *)open
{
    [self lock];
    if (self.state != SGPacketOutputStateNone)
    {
        [self unlock];
        return SGECreateError(SGErrorCodePacketOutputCannotOpen, SGOperationCodePacketOutputOpen);
    }
    SGBasicBlock callback = [self setState:SGPacketOutputStateOpening];
    [self unlock];
    callback();
    [self startOpenThread];
    return nil;
}

- (NSError *)start
{
    return [self resume];
}

- (NSError *)close
{
    [self lock];
    if (self.state == SGPacketOutputStateClosed)
    {
        [self unlock];
        return SGECreateError(SGErrorCodePacketOutputCannotClose, SGOperationCodePacketOutputClose);
    }
    SGBasicBlock callback = [self setState:SGPacketOutputStateClosed];
    [self unlock];
    callback();
    [self.operationQueue cancelAllOperations];
    [self.operationQueue waitUntilAllOperationsAreFinished];
    self.operationQueue = nil;
    self.openOperation = nil;
    self.readOperation = nil;
    [self.readable close];
    return nil;
}

- (NSError *)pause
{
    [self lock];
    if (self.state != SGPacketOutputStateReading &&
        self.state != SGPacketOutputStateSeeking)
    {
        [self unlock];
        return SGECreateError(SGErrorCodePacketOutputCannotPause, SGOperationCodePacketOutputPause);
    }
    SGBasicBlock callback = [self setState:SGPacketOutputStatePaused];
    [self unlock];
    callback();
    return nil;
}

- (NSError *)resume
{
    [self lock];
    if (self.state != SGPacketOutputStatePaused &&
        self.state != SGPacketOutputStateOpened)
    {
        [self unlock];
        return SGECreateError(SGErrorCodePacketOutputCannotResume, SGOperationCodePacketOutputResmue);
    }
    SGBasicBlock callback = [self setState:SGPacketOutputStateReading];
    [self unlock];
    callback();
    return nil;
}

#pragma mark - Seeking

- (NSError *)seekable
{
    return [self.readable seekable];
}

- (NSError *)seekToTime:(CMTime)time completionHandler:(void (^)(CMTime, NSError *))completionHandler
{
    NSError * error = [self seekable];
    if (error)
    {
        return error;
    }
    [self lock];
    if (self.state != SGPacketOutputStateReading &&
        self.state != SGPacketOutputStatePaused &&
        self.state != SGPacketOutputStateSeeking &&
        self.state != SGPacketOutputStateFinished)
    {
        [self unlock];
        return SGECreateError(SGErrorCodePacketOutputCannotSeek, SGOperationCodePacketOutputSeek);
    }
    SGBasicBlock callback = [self setState:SGPacketOutputStateSeeking];
    self.seekTimeStamp = time;
    self.seekCompletionHandler = completionHandler;
    [self unlock];
    callback();
    return nil;
}

#pragma mark - Open

- (void)startOpenThread
{
    SGWeakSelf
    self.openOperation = [NSBlockOperation blockOperationWithBlock:^{
        SGStrongSelf
        [self openThread];
    }];
    self.openOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.openOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    self.openOperation.name = [NSString stringWithFormat:@"%@-Open-Queue", self.class];
    [self.operationQueue addOperation:self.openOperation];
}

- (void)openThread
{
    NSError * error = [self.readable open];
    [self lock];
    SGPacketOutputState state = error ? SGPacketOutputStateFailed : SGPacketOutputStateOpened;
    SGBasicBlock callback = [self setState:state];
    [self unlock];
    callback();
}

#pragma mark - Read

- (void)startReadThread
{
    SGWeakSelf
    self.readOperation = [NSBlockOperation blockOperationWithBlock:^{
        SGStrongSelf
        [self readThread];
    }];
    self.readOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.readOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    self.readOperation.name = [NSString stringWithFormat:@"%@-Read-Queue", self.class];
    [self.readOperation addDependency:self.openOperation];
    [self.operationQueue addOperation:self.readOperation];
}

- (void)readThread
{
    while (YES)
    {
        @autoreleasepool
        {
            [self lock];
            if (self.state == SGPacketOutputStateNone ||
                self.state == SGPacketOutputStateFinished ||
                self.state == SGPacketOutputStateClosed ||
                self.state == SGPacketOutputStateFailed)
            {
                [self unlock];
                break;
            }
            else if (self.state == SGPacketOutputStatePaused)
            {
                [self.pausedCondition lock];
                [self unlock];
                [self.pausedCondition wait];
                [self.pausedCondition unlock];
                continue;
            }
            else if (self.state == SGPacketOutputStateSeeking)
            {
                self.seekingTimeStamp = self.seekTimeStamp;
                CMTime seekingTimeStamp = self.seekingTimeStamp;
                [self unlock];
                NSError * error = [self.readable seekToTime:seekingTimeStamp];
                [self lock];
                if (self.state == SGPacketOutputStateSeeking &&
                    CMTimeCompare(self.seekTimeStamp, seekingTimeStamp) != 0)
                {
                    [self unlock];
                    continue;
                }
                SGBasicBlock callback = [self setState:SGPacketOutputStateReading];
                CMTime seekTimeStamp = self.seekTimeStamp;
                void(^seekCompletionHandler)(CMTime, NSError *) = self.seekCompletionHandler;
                self.seekTimeStamp = kCMTimeZero;
                self.seekingTimeStamp = kCMTimeZero;
                self.seekCompletionHandler = nil;
                [self unlock];
                if (seekCompletionHandler)
                {
                    seekCompletionHandler(seekTimeStamp, error);
                }
                callback();
                continue;
            }
            else if (self.state == SGPacketOutputStateReading)
            {
                [self unlock];
                SGPacket * packet = [[SGObjectPool sharePool] objectWithClass:[SGPacket class]];
                NSError * error = [self.readable nextPacket:packet];
                if (error)
                {
                    [self lock];
                    SGBasicBlock callback = ^{};
                    if (self.state == SGPacketOutputStateReading)
                    {
                        callback = [self setState:SGPacketOutputStateFinished];
                    }
                    [self unlock];
                    callback();
                }
                else
                {
                    for (SGStream * obj in self.readable.streams)
                    {
                        if (obj.index == packet.core->stream_index)
                        {
                            [packet configurateWithStream:obj];
                            break;
                        }
                    }
                    [self.delegate packetOutput:self didOutputPacket:packet];
                }
                [packet unlock];
                continue;
            }
        }
    }
}

#pragma mark - SGPacketReaderDelegate

- (BOOL)packetReadableShouldAbortBlockingFunctions:(id <SGPacketReadable>)packetReadable
{
    [self lock];
    BOOL ret = NO;
    switch (self.state)
    {
        case SGPacketOutputStateFinished:
        case SGPacketOutputStateClosed:
        case SGPacketOutputStateFailed:
            ret = YES;
            break;
        case SGPacketOutputStateSeeking:
            ret = CMTimeCompare(self.seekTimeStamp, self.seekingTimeStamp) != 0;
            break;
        default:
            break;
    }
    [self unlock];
    return ret;
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
