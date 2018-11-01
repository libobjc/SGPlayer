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
#import "SGPointerMap.h"
#import "SGMapping.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGFrameOutput () <SGPacketOutputDelegate, SGAsyncDecoderDelegate>

{
    SGFrameOutputState _state;
}

@property (nonatomic, strong) NSError * error;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) SGPointerMap * capacityMap;
@property (nonatomic, strong) SGPacketOutput * packetOutput;
@property (nonatomic, strong) SGAsyncDecoder * audioDecoder;
@property (nonatomic, strong) SGAsyncDecoder * videoDecoder;
@property (nonatomic, assign) BOOL audioFinished;
@property (nonatomic, assign) BOOL videoFinished;
@property (nonatomic, assign) BOOL audioPaused;
@property (nonatomic, assign) BOOL videoPaused;

@end

@implementation SGFrameOutput

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self.coreLock = [[NSLock alloc] init];
        self.capacityMap = [[SGPointerMap alloc] init];
        self.packetOutput = [[SGPacketOutput alloc] initWithAsset:asset];
        self.packetOutput.delegate = self;
    }
    return self;
}

#pragma mark - Mapping

SGGet0Map(CMTime, duration, self.packetOutput)
SGGet0Map(NSDictionary *, metadata, self.packetOutput)
SGGet0Map(NSArray <SGTrack *> *, tracks, self.packetOutput)
SGGet0Map(NSArray <SGTrack *> *, audioTracks, self.packetOutput)
SGGet0Map(NSArray <SGTrack *> *, videoTracks, self.packetOutput)
SGGet0Map(NSArray <SGTrack *> *, otherTracks, self.packetOutput)

#pragma mark - Setter & Getter

- (SGBlock)setState:(SGFrameOutputState)state
{
    if (_state == state) {
        return ^{};
    }
    _state = state;
    return ^{
        [self.delegate frameOutput:self didChangeState:state];
    };
}

- (SGFrameOutputState)state
{
    __block SGFrameOutputState ret = SGFrameOutputStateNone;
    SGLockEXE00(self.coreLock, ^{
        ret = self->_state;
    });
    return ret;
}

- (SGCapacity *)capacityWithTrack:(SGTrack *)track
{
    __block SGCapacity * ret = nil;
    SGLockEXE00(self.coreLock, ^{
        ret = [[self.capacityMap objectForKey:track] copy];
    });
    return ret ? ret : [[SGCapacity alloc] init];
}

- (void)setFinishedIfNeeded
{
    if (self.packetOutput.state == SGPacketOutputStateFinished &&
        (!self.selectedAudioTrack || self.audioFinished) &&
        (!self.selectedVideoTrack || self.videoFinished)) {
        SGLockEXE10(self.coreLock, ^SGBlock {
            return [self setState:SGFrameOutputStateFinished];
        });
    }
}

#pragma mark - Interface

- (BOOL)open
{
    return [self.packetOutput open];
}

- (BOOL)start
{
    return [self.packetOutput start];
}

- (BOOL)close
{
    [self.packetOutput close];
    [self.audioDecoder close];
    [self.videoDecoder close];
    return YES;
}

- (BOOL)pause:(SGMediaType)type
{
    if (type == SGMediaTypeAudio) {
        [self.audioDecoder pause];
    } else if (type == SGMediaTypeVideo) {
        [self.videoDecoder pause];
    }
    return YES;
}

- (BOOL)resume:(SGMediaType)type
{
    if (type == SGMediaTypeAudio) {
        [self.audioDecoder resume];
    } else if (type == SGMediaTypeVideo) {
        [self.videoDecoder resume];
    }
    return YES;
}

#pragma mark - Seek

- (BOOL)seekable
{
    return [self.packetOutput seekable];
}

- (BOOL)seekToTime:(CMTime)time result:(SGSeekResultBlock)result
{
    SGWeakSelf
    return [self.packetOutput seekToTime:time result:^(CMTime time, NSError * error) {
        SGStrongSelf
        [self.audioDecoder flush];
        [self.videoDecoder flush];
        if (result) {
            result(time, error);
        }
    }];
}

#pragma mark - SGPacketOutputDelegate

- (void)packetOutput:(SGPacketOutput *)packetOutput didChangeState:(SGPacketOutputState)state
{
    SGLockEXE10(self.coreLock, ^SGBlock {
        SGBlock stateBlock = ^{};
        SGBlock audioBlock = ^{};
        SGBlock videoBlock = ^{};
        switch (state)
        {
            case SGPacketOutputStateNone:
                stateBlock = [self setState:SGFrameOutputStateNone];
                break;
            case SGPacketOutputStateOpening:
                stateBlock = [self setState:SGFrameOutputStateOpening];
                break;
            case SGPacketOutputStateOpened:
            {
                stateBlock = [self setState:SGFrameOutputStateOpened];
                self.selectedAudioTrack = self.audioTracks.firstObject;
                self.selectedVideoTrack = self.videoTracks.firstObject;
                if (self.selectedAudioTrack) {
                    self.audioDecoder = [[SGAsyncDecoder alloc] initWithDecodable:[[SGAudioDecoder alloc] init]];
                    self.audioDecoder.delegate = self;
                    audioBlock = ^{
                        [self.audioDecoder open];
                    };
                }
                if (self.selectedVideoTrack) {
                    self.videoDecoder = [[SGAsyncDecoder alloc] initWithDecodable:[[SGVideoDecoder alloc] init]];
                    self.videoDecoder.delegate = self;
                    videoBlock = ^{
                        [self.videoDecoder open];
                    };
                }
            }
                break;
            case SGPacketOutputStateReading:
                stateBlock = [self setState:SGFrameOutputStateReading];
                break;
            case SGPacketOutputStatePaused:
                stateBlock = [self setState:SGFrameOutputStatePaused];
                break;
            case SGPacketOutputStateSeeking:
                stateBlock = [self setState:SGFrameOutputStateSeeking];
                break;
            case SGPacketOutputStateFinished:
            {
                audioBlock = ^{
                    [self.audioDecoder finish];
                };
                videoBlock = ^{
                    [self.videoDecoder finish];
                };
            }
                break;
            case SGPacketOutputStateClosed:
                stateBlock = [self setState:SGFrameOutputStateClosed];
                break;
            case SGPacketOutputStateFailed:
                self.error = packetOutput.error;
                stateBlock = [self setState:SGFrameOutputStateFailed];
                break;
        }
        return ^{
            stateBlock();
            audioBlock();
            videoBlock();
        };
    });
}

- (void)packetOutput:(SGPacketOutput *)packetOutput didOutputPacket:(SGPacket *)packet
{
    __block SGAsyncDecoder * decoder = nil;
    if (packet.track == self.selectedAudioTrack) {
        decoder = self.audioDecoder;
    } else if (packet.track == self.selectedVideoTrack) {
        decoder = self.videoDecoder;
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
    SGTrack * track = nil;
    if (decoder.decodable.type == SGMediaTypeAudio) {
        track = self.selectedAudioTrack;
    } else if (decoder.decodable.type == SGMediaTypeVideo) {
        track = self.selectedVideoTrack;
    }
    if (!track) {
        return;
    }
    capacity = [capacity copy];
    SGLockCondEXE11(self.coreLock, ^BOOL {
        SGCapacity * last = [self.capacityMap objectForKey:track];
        return ![last isEqualToCapacity:capacity];
    }, ^SGBlock {
        [self.capacityMap setObject:capacity forKey:track];
        return nil;
    }, ^BOOL(SGBlock block) {
        BOOL paused = capacity.count > 30 && CMTimeCompare(capacity.duration, CMTimeMake(1, 1)) > 0;
        BOOL finished = self.packetOutput.state == SGPacketOutputStateFinished && capacity.count == 0;
        if (track.type == SGMediaTypeAudio) {
            self.audioPaused = paused;
            self.audioFinished = finished;
        } else if (track.type == SGMediaTypeVideo) {
            self.videoPaused = paused;
            self.videoFinished = finished;
        }
        if (self.audioPaused && self.videoPaused) {
            [self.packetOutput pause];
        } else {
            [self.packetOutput resume];
        }
        [self.delegate frameOutput:self didChangeCapacity:[capacity copy] track:track];
        [self setFinishedIfNeeded];
        return YES;
    });
}

@end
