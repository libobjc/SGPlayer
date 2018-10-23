//
//  SGFrameOutput.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/22.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrameOutput.h"
#import "SGPacketOutput.h"
#import "SGAudioDecoder.h"
#import "SGVideoDecoder.h"
#import "SGAsyncDecoder.h"
#import "SGMacro.h"

@interface SGFrameOutput () <SGPacketOutputDelegate, SGAsyncDecoderDelegate>

{
    SGFrameOutputState _state;
}

@property (nonatomic, strong) SGPacketOutput * packetOutput;
@property (nonatomic, strong) NSMutableArray <SGAsyncDecoder *> * decoders;
@property (nonatomic, strong) NSMutableArray <NSNumber *> * fullyDecoders;
@property (nonatomic, strong) NSLock * coreLock;

@end

@implementation SGFrameOutput

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init])
    {
        self.packetOutput = [[SGPacketOutput alloc] initWithAsset:asset];
        self.packetOutput.delegate = self;
    }
    return self;
}

#pragma mark - Setter & Getter

- (SGBasicBlock)setState:(SGFrameOutputState)state
{
    if (_state != state)
    {
        _state = state;
        return ^{
            [self.delegate frameOutput:self didChangeState:state];
        };
    }
    return ^{};
}

- (SGFrameOutputState)state
{
    return _state;
}

- (NSError *)error
{
    return self.packetOutput.error;
}

- (CMTime)duration
{
    return self.packetOutput.duration;
}

- (NSDictionary *)metadata
{
    return self.packetOutput.metadata;
}

- (NSArray <SGStream *> *)streams
{
    return self.packetOutput.streams;
}

- (NSArray <SGStream *> *)audioStreams
{
    return self.packetOutput.audioStreams;
}

- (NSArray <SGStream *> *)videoStreams
{
    return self.packetOutput.videoStreams;
}

- (NSArray <SGStream *> *)otherStreams
{
    return self.packetOutput.otherStreams;
}

- (BOOL)duratioin:(CMTime *)duration size:(int64_t *)size count:(NSUInteger *)count stream:(SGStream *)stream
{
    for (SGAsyncDecoder * obj in self.decoders) {
        if (obj.object == stream) {
            return [obj duratioin:duration size:size count:count];
        }
    }
    return NO;
}

#pragma mark - Interface

- (NSError *)open
{
    return [self.packetOutput open];
}

- (NSError *)start
{
    return [self.packetOutput start];
}

- (NSError *)close
{
    NSError * error = [self.packetOutput close];
    for (SGAsyncDecoder * obj in self.decoders) {
        [obj close];
    }
    return error;
}

- (NSError *)pause:(NSArray <SGStream *> *)streams
{
    for (SGAsyncDecoder * obj in self.decoders) {
        if ([streams containsObject:obj.object]) {
            [obj pause];
        }
    }
    return nil;
}

- (NSError *)resume:(NSArray <SGStream *> *)streams
{
    for (SGAsyncDecoder * obj in self.decoders) {
        if ([streams containsObject:obj.object]) {
            [obj resume];
        }
    }
    return nil;
}

#pragma mark - Seeking

- (NSError *)seekable
{
    return [self.packetOutput seekable];
}

- (NSError *)seekToTime:(CMTime)time completionHandler:(void (^)(CMTime, NSError *))completionHandler
{
    SGWeakSelf
    return [self.packetOutput seekToTime:time completionHandler:^(CMTime time, NSError *error) {
        SGStrongSelf
        for (SGAsyncDecoder * obj in self.decoders) {
            [obj flush];
        }
        if (completionHandler) {
            completionHandler(time, error);
        }
    }];
}

#pragma mark - SGPacketOutputDelegate

- (void)packetOutput:(SGPacketOutput *)packetOutput didChangeState:(SGPacketOutputState)state
{
    SGFrameOutputState frameState = SGFrameOutputStateNone;
    switch (state)
    {
        case SGPacketOutputStateNone:
            frameState = SGFrameOutputStateNone;
            break;
        case SGPacketOutputStateOpening:
            frameState = SGFrameOutputStateOpening;
            break;
        case SGPacketOutputStateOpened:
        {
            frameState = SGFrameOutputStateOpened;
            NSMutableArray * streams = [NSMutableArray array];
            if (self.audioStreams.firstObject) {
                [streams addObject:self.audioStreams.firstObject];
            }
            if (self.videoStreams.firstObject) {
                [streams addObject:self.videoStreams.firstObject];
            }
            self.outputStreams = [streams copy];
            self.decoders = [NSMutableArray array];
            self.fullyDecoders = [NSMutableArray array];
        }
            break;
        case SGPacketOutputStateReading:
            frameState = SGFrameOutputStateReading;
            break;
        case SGPacketOutputStatePaused:
            frameState = SGFrameOutputStatePaused;
            break;
        case SGPacketOutputStateSeeking:
            frameState = SGFrameOutputStateSeeking;
            break;
        case SGPacketOutputStateFinished:
            frameState = SGFrameOutputStateFinished;
            break;
        case SGPacketOutputStateClosed:
            frameState = SGFrameOutputStateClosed;
            break;
        case SGPacketOutputStateFailed:
            frameState = SGFrameOutputStateFailed;
            break;
    }
    [self lock];
    SGBasicBlock callback = [self setState:frameState];
    [self unlock];
    callback();
}

- (void)packetOutput:(SGPacketOutput *)packetOutput didOutputPacket:(SGPacket *)packet
{
    if (![self.outputStreams containsObject:packet.stream]) {
        return;
    }
    SGAsyncDecoder * decoder = nil;
    for (SGAsyncDecoder * obj in self.decoders) {
        if (obj.object == packet.stream) {
            decoder = obj;
            break;
        }
    }
    if (!decoder) {
        id <SGDecodable> decodable = nil;
        if (packet.stream.mediaType == SGMediaTypeAudio) {
            decodable = [[SGAudioDecoder alloc] init];
        } else if (packet.stream.mediaType == SGMediaTypeVideo) {
            decodable = [[SGVideoDecoder alloc] init];
        }
        if (decodable) {
            SGAsyncDecoder * async = [[SGAsyncDecoder alloc] initWithDecodable:decodable];
            async.object = packet.stream;
            async.delegate = self;
            [async open];
            decoder = async;
            [self lock];
            [self.decoders addObject:decoder];
            [self.fullyDecoders addObject:@(NO)];
            [self unlock];
        }
    }
    if (!decoder) {
        return;
    }
    [decoder putPacket:packet];
}

#pragma mark - SGDecoderDelegate

- (void)decoder:(SGAsyncDecoder *)decoder didChangeState:(SGAsyncDecoderState)state
{
    
}

- (void)decoder:(SGAsyncDecoder *)decoder didChangeCapacity:(CMTime)duration size:(int64_t)size count:(NSUInteger)count
{
    [self lock];
    BOOL full = count > 30 && CMTimeCompare(duration, CMTimeMake(1, 1)) > 0;
    NSUInteger index = [self.decoders indexOfObject:decoder];
    [self.fullyDecoders replaceObjectAtIndex:index withObject:@(full)];
    BOOL pause = YES;
    for (NSNumber * obj in self.fullyDecoders) {
        pause = pause && obj.boolValue;
    }
    [self unlock];
    if (pause) {
        [self.packetOutput pause];
    } else {
        [self.packetOutput resume];
    }
    [self.delegate frameOutput:self didChangeCapacity:duration size:size count:count stream:decoder.object];
}

- (void)decoder:(SGAsyncDecoder *)decoder didOutputFrame:(SGFrame *)frame
{
    [self.delegate frameOutput:self didOutputFrame:frame];
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
