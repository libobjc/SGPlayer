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
@property (nonatomic, strong) NSArray * selectedTracksInternal;
@property (nonatomic, strong) SGTrack * selectedAudioTrack;
@property (nonatomic, strong) SGTrack * selectedVideoTrack;
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

#pragma mark - Mapping

SGGet0Map(NSError *, error, self.packetOutput)
SGGet0Map(CMTime, duration, self.packetOutput)
SGGet0Map(NSDictionary *, metadata, self.packetOutput)
SGGet0Map(NSArray <SGTrack *> *, tracks, self.packetOutput)
SGGet0Map(NSArray <SGTrack *> *, audioTracks, self.packetOutput)
SGGet0Map(NSArray <SGTrack *> *, videoTracks, self.packetOutput)
SGGet0Map(NSArray <SGTrack *> *, otherTracks, self.packetOutput)

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

- (NSArray <SGTrack *> *)selectedTracks
{
    NSArray * ret = nil;
    [self lock];
    ret = [self.selectedTracksInternal copy];
    [self unlock];
    return ret;
}

- (void)setSelectedTracks:(NSArray <SGTrack *> *)selectedTracks
{
    [self lock];
    self.selectedTracksInternal = nil;
    self.selectedAudioTrack = nil;
    self.selectedVideoTrack = nil;
    NSMutableArray * ret = [NSMutableArray array];
    for (SGTrack * obj in selectedTracks) {
        if (self.selectedAudioTrack && self.selectedVideoTrack) {
            break;
        }
        if (!self.selectedAudioTrack && obj.type == SGMediaTypeAudio) {
            self.selectedAudioTrack = obj;
            [ret addObject:obj];
        } else if (!self.selectedVideoTrack && obj.type == SGMediaTypeVideo) {
            self.selectedVideoTrack = obj;
            [ret addObject:obj];
        }
    }
    [ret sortUsingComparator:^NSComparisonResult(SGTrack * obj1, SGTrack * obj2) {
        if (obj1.type == SGMediaTypeAudio) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
    self.selectedTracksInternal = [ret copy];
    [self unlock];
}

- (NSArray <SGCapacity *> *)capacityWithTracks:(NSArray <SGTrack *> *)tracks
{
    NSMutableArray * ret = [NSMutableArray array];
    for (SGAsyncDecoder * obj in self.decoders) {
        if ([tracks containsObject:obj.object]) {
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

- (NSError *)pause:(NSArray <SGTrack *> *)tracks
{
    for (SGAsyncDecoder * obj in self.decoders) {
        if ([tracks containsObject:obj.object]) {
            [obj pause];
        }
    }
    return nil;
}

- (NSError *)resume:(NSArray <SGTrack *> *)tracks
{
    for (SGAsyncDecoder * obj in self.decoders) {
        if ([tracks containsObject:obj.object]) {
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
            NSMutableArray * tracks = [NSMutableArray array];
            if (self.audioTracks.firstObject) {
                [tracks addObject:self.audioTracks.firstObject];
            }
            if (self.videoTracks.firstObject) {
                [tracks addObject:self.videoTracks.firstObject];
            }
            self.selectedTracks = [tracks copy];
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
    if (![self.selectedTracksInternal containsObject:packet.track]) {
        [self unlock];
        return;
    }
    SGAsyncDecoder * decoder = nil;
    for (SGAsyncDecoder * obj in self.decoders) {
        if (obj.object == packet.track) {
            decoder = obj;
            break;
        }
    }
    if (!decoder) {
        id <SGDecodable> decodable = nil;
        if (packet.track.type == SGMediaTypeAudio) {
            decodable = [[SGAudioDecoder alloc] init];
        } else if (packet.track
                   .type == SGMediaTypeVideo) {
            decodable = [[SGVideoDecoder alloc] init];
        }
        if (decodable) {
            SGAsyncDecoder * async = [[SGAsyncDecoder alloc] initWithDecodable:decodable];
            async.object = packet.track;
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
        if ([self.selectedTracksInternal containsObject:obj.object]) {
            paused = paused && value;
        }
    }
    [self unlock];
    if (paused) {
        [self.packetOutput pause];
    } else {
        [self.packetOutput resume];
    }
    [self.delegate frameOutput:self didChangeCapacity:capacity track:decoder.object];
    [self callbackForFinishedIfNeeded];
}

#pragma mark - Callback

- (void)callbackForFinishedIfNeeded
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
            if ([self.selectedTracks containsObject:obj.object]) {
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
