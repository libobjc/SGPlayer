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
#import "SGMapping.h"
#import "SGMacro.h"

@interface SGFrameOutput () <SGPacketOutputDelegate, SGAsyncDecoderDelegate>

{
    SGFrameOutputState _state;
}

@property (nonatomic, strong) SGPacketOutput * packetOutput;
@property (nonatomic, strong) NSArray * selectedStreamsInternal;
@property (nonatomic, strong) SGStream * selectedAudioStream;
@property (nonatomic, strong) SGStream * selectedVideoStream;
@property (nonatomic, strong) NSMutableArray <SGAsyncDecoder *> * decoders;
@property (nonatomic, strong) NSMutableArray <NSNumber *> * decodersPaused;
@property (nonatomic, strong) NSRecursiveLock * coreLock;

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

- (NSArray <SGStream *> *)selectedStreams
{
    NSArray * ret = nil;
    [self lock];
    ret = [self.selectedStreamsInternal copy];
    [self unlock];
    return ret;
}

- (void)setSelectedStreams:(NSArray <SGStream *> *)selectedStreams
{
    [self lock];
    self.selectedStreamsInternal = nil;
    self.selectedAudioStream = nil;
    self.selectedVideoStream = nil;
    NSMutableArray * ret = [NSMutableArray array];
    for (SGStream * obj in selectedStreams) {
        if (self.selectedAudioStream && self.selectedVideoStream) {
            break;
        }
        if (!self.selectedAudioStream && obj.type == SGMediaTypeAudio) {
            self.selectedAudioStream = obj;
            [ret addObject:obj];
        } else if (!self.selectedVideoStream && obj.type == SGMediaTypeVideo) {
            self.selectedVideoStream = obj;
            [ret addObject:obj];
        }
    }
    [ret sortUsingComparator:^NSComparisonResult(SGStream * obj1, SGStream * obj2) {
        if (obj1.type == SGMediaTypeAudio) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
    self.selectedStreamsInternal = [ret copy];
    [self unlock];
}

- (NSArray <SGCapacity *> *)capacityWithStreams:(NSArray <SGStream *> *)streams
{
    NSMutableArray * ret = [NSMutableArray array];
    for (SGAsyncDecoder * obj in self.decoders) {
        if ([streams containsObject:obj.object]) {
            SGCapacity * c = obj.capacity;
            c.object = obj.object;
            [ret addObject:c];
        }
    }
    return [ret copy];
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
    [self lock];
    SGFrameOutputState frameState = self.state;
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
            self.selectedStreams = [streams copy];
            self.decoders = [NSMutableArray array];
            self.decodersPaused = [NSMutableArray array];
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
            for (SGAsyncDecoder * obj in self.decoders) {
                [obj finish];
            }
            break;
        case SGPacketOutputStateClosed:
            frameState = SGFrameOutputStateClosed;
            break;
        case SGPacketOutputStateFailed:
            frameState = SGFrameOutputStateFailed;
            break;
    }
    SGBasicBlock callback = [self setState:frameState];
    [self unlock];
    callback();
}

- (void)packetOutput:(SGPacketOutput *)packetOutput didOutputPacket:(SGPacket *)packet
{
    [self lock];
    if (![self.selectedStreamsInternal containsObject:packet.stream]) {
        [self unlock];
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
        if (packet.stream.type == SGMediaTypeAudio) {
            decodable = [[SGAudioDecoder alloc] init];
        } else if (packet.stream.type == SGMediaTypeVideo) {
            decodable = [[SGVideoDecoder alloc] init];
        }
        if (decodable) {
            SGAsyncDecoder * async = [[SGAsyncDecoder alloc] initWithDecodable:decodable];
            async.object = packet.stream;
            async.delegate = self;
            [async open];
            decoder = async;
            [self.decoders addObject:decoder];
            [self.decodersPaused addObject:@(NO)];
        }
    }
    [self unlock];
    if (!decoder) {
        return;
    }
    [decoder putPacket:packet];
}

#pragma mark - SGDecoderDelegate

- (void)decoder:(SGAsyncDecoder *)decoder didOutputFrame:(SGFrame *)frame
{
    [self.delegate frameOutput:self didOutputFrame:frame];
}

- (void)decoder:(SGAsyncDecoder *)decoder didChangeState:(SGAsyncDecoderState)state
{
    
}

- (void)decoder:(SGAsyncDecoder *)decoder didChangeCapacity:(SGCapacity *)capacity
{
    BOOL paused = capacity.count > 30 && CMTimeCompare(capacity.duration, CMTimeMake(1, 1)) > 0;
    [self lock];
    NSUInteger index = [self.decoders indexOfObject:decoder];
    [self.decodersPaused replaceObjectAtIndex:index withObject:@(paused)];
    for (NSUInteger i = 0; i < self.decoders.count; i++) {
        SGAsyncDecoder * obj = [self.decoders objectAtIndex:i];
        BOOL value = [self.decodersPaused objectAtIndex:i].boolValue;
        if ([self.selectedStreamsInternal containsObject:obj.object]) {
            paused = paused && value;
        }
    }
    [self unlock];
    if (paused) {
        [self.packetOutput pause];
    } else {
        [self.packetOutput resume];
    }
    [self.delegate frameOutput:self didChangeCapacity:capacity stream:decoder.object];
    [self callbackForFinisehdIfNeeded];
}

#pragma mark - Callback

- (void)callbackForFinisehdIfNeeded
{
    if ([self finished]) {
        [self lock];
        SGBasicBlock callback = [self setState:SGFrameOutputStateFinished];
        [self unlock];
        callback();
    }
}

- (BOOL)finished
{
    BOOL finished = self.packetOutput.state == SGPacketOutputStateFinished;
    if (finished) {
        [self lock];
        for (SGAsyncDecoder * obj in self.decoders) {
            if ([self.selectedStreams containsObject:obj.object]) {
                finished = finished && obj.capacity.count == 0;
            }
        }
        [self unlock];
    }
    return finished;
}

#pragma mark - NSLocking

- (void)lock
{
    if (!self.coreLock)
    {
        self.coreLock = [[NSRecursiveLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
