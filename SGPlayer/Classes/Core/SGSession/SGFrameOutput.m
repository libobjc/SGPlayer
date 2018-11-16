//
//  SGFrameOutput.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/22.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrameOutput.h"
#import "SGAsset+Internal.h"
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
    BOOL _audio_available;
    BOOL _video_available;
    BOOL _audio_finished;
    BOOL _video_finished;
    __strong NSError * _error;
    __strong SGTrack * _selected_audio_track;
    __strong SGTrack * _selected_video_track;
}

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) SGPointerMap * capacityMap;
@property (nonatomic, strong) SGPacketOutput * packetOutput;
@property (nonatomic, strong) SGAsyncDecoder * audioDecoder;
@property (nonatomic, strong) SGAsyncDecoder * videoDecoder;

@end

@implementation SGFrameOutput

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self.lock = [[NSLock alloc] init];
        self.capacityMap = [[SGPointerMap alloc] init];
        self.packetOutput = [[SGPacketOutput alloc] initWithDemuxable:[asset newDemuxable]];
        self.packetOutput.delegate = self;
    }
    return self;
}

#pragma mark - Mapping

SGGet0Map(CMTime, duration, self.packetOutput)
SGGet0Map(NSDictionary *, metadata, self.packetOutput)
SGGet0Map(NSArray <SGTrack *> *, tracks, self.packetOutput)

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
    SGLockEXE00(self.lock, ^{
        ret = self->_state;
    });
    return ret;
}

- (NSError *)error
{
    __block NSError * ret = nil;
    SGLockEXE00(self.lock, ^{
        ret = [self->_error copy];
    });
    return ret;
}

- (BOOL)audioFinished
{
    __block BOOL ret = NO;
    SGLockEXE00(self.lock, ^{
        ret = self->_audio_finished;
    });
    return ret;
}

- (BOOL)videoFinished
{
    __block BOOL ret = NO;
    SGLockEXE00(self.lock, ^{
        ret = self->_video_finished;
    });
    return ret;
}

- (void)setSelectedAudioTrack:(SGTrack *)selectedAudioTrack
{
    SGLockCondEXE10(self.lock, ^BOOL {
        return self->_selected_audio_track != selectedAudioTrack;
    }, ^SGBlock {
        self->_selected_audio_track = selectedAudioTrack;
        return nil;
    });
}

- (SGTrack *)selectedAudioTrack
{
    __block SGTrack * ret = nil;
    SGLockEXE00(self.lock, ^{
        ret = self->_selected_audio_track;
    });
    return ret;
}

- (void)setSelectedVideoTrack:(SGTrack *)selectedVideoTrack
{
    SGLockCondEXE10(self.lock, ^BOOL {
        return self->_selected_video_track != selectedVideoTrack;
    }, ^SGBlock {
        self->_selected_video_track = selectedVideoTrack;
        return nil;
    });
}

- (SGTrack *)selectedVideoTrack
{
    __block SGTrack * ret = nil;
    SGLockEXE00(self.lock, ^{
        ret = self->_selected_video_track;
    });
    return ret;
}

- (SGCapacity *)capacityWithTrack:(SGTrack *)track
{
    __block SGCapacity * ret = nil;
    SGLockEXE00(self.lock, ^{
        ret = [[self.capacityMap objectForKey:track] copy];
    });
    return ret ? ret : [[SGCapacity alloc] init];
}

- (void)setFinishedIfNeeded
{
    if (self.packetOutput.state == SGPacketOutputStateFinished) {
        SGLockCondEXE10(self.lock, ^BOOL {
            return (!self->_audio_available || self->_audio_finished) && (!self->_video_available || self->_video_finished);
        }, ^SGBlock {
            return [self setState:SGFrameOutputStateFinished];
        });
    }
}

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state == SGFrameOutputStateNone;
    }, ^SGBlock {
        return [self setState:SGFrameOutputStateOpening];
    }, ^BOOL(SGBlock block) {
        block();
        return [self.packetOutput open];
    });
}

- (BOOL)start
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state == SGFrameOutputStateOpened;
    }, ^SGBlock {
        return [self setState:SGFrameOutputStateReading];
    }, ^BOOL(SGBlock block) {
        block();
        return [self.packetOutput resume];
    });
}

- (BOOL)close
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state != SGFrameOutputStateClosed;
    }, ^SGBlock {
        return [self setState:SGFrameOutputStateClosed];
    }, ^BOOL(SGBlock block) {
        block();
        [self.packetOutput close];
        [self.audioDecoder close];
        [self.videoDecoder close];
        return YES;
    });
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
    SGWeakify(self)
    return [self.packetOutput seekToTime:time result:^(CMTime time, NSError * error) {
        SGStrongify(self)
        if (!error) {
            [self.audioDecoder flush];
            [self.videoDecoder flush];
        }
        if (result) {
            result(time, error);
        }
    }];
}

#pragma mark - SGPacketOutputDelegate

- (void)packetOutput:(SGPacketOutput *)packetOutput didChangeState:(SGPacketOutputState)state
{
    SGLockEXE10(self.lock, ^SGBlock {
        SGBlock b1 = ^{}, b2 = ^{}, b3 = ^{};
        switch (state) {
            case SGPacketOutputStateNone:
                b1 = [self setState:SGFrameOutputStateNone];
                break;
            case SGPacketOutputStateOpening:
                b1 = [self setState:SGFrameOutputStateOpening];
                break;
            case SGPacketOutputStateOpened: {
                b1 = [self setState:SGFrameOutputStateOpened];
                for (SGTrack * obj in packetOutput.tracks) {
                    if (!self->_selected_audio_track && obj.type == SGMediaTypeAudio) {
                        self->_selected_audio_track = obj;
                        self.audioDecoder = [[SGAsyncDecoder alloc] initWithDecodable:[[SGAudioDecoder alloc] init]];
                        self.audioDecoder.delegate = self;
                        b2 = ^{
                            [self.audioDecoder open];
                        };
                    }
                    if (!self->_selected_video_track && obj.type == SGMediaTypeVideo) {
                        self->_selected_video_track = obj;
                        self.videoDecoder = [[SGAsyncDecoder alloc] initWithDecodable:[[SGVideoDecoder alloc] init]];
                        self.videoDecoder.delegate = self;
                        b3 = ^{
                            [self.videoDecoder open];
                        };
                    }
                }
            }
                break;
            case SGPacketOutputStateReading:
                b1 = [self setState:SGFrameOutputStateReading];
                break;
            case SGPacketOutputStatePaused:
                b1 = [self setState:SGFrameOutputStatePaused];
                break;
            case SGPacketOutputStateSeeking:
                b1 = [self setState:SGFrameOutputStateSeeking];
                break;
            case SGPacketOutputStateFinished: {
                b1 = ^{
                    [self.audioDecoder finish];
                    [self.videoDecoder finish];
                };
            }
                break;
            case SGPacketOutputStateClosed:
                b1 = [self setState:SGFrameOutputStateClosed];
                break;
            case SGPacketOutputStateFailed:
                self->_error = [packetOutput.error copy];
                b1 = [self setState:SGFrameOutputStateFailed];
                break;
        }
        return ^{
            b1(); b2(); b3();
        };
    });
}

- (void)packetOutput:(SGPacketOutput *)packetOutput didOutputPacket:(SGPacket *)packet
{
    __block SGAsyncDecoder * decoder = nil;
    SGLockEXE00(self.lock, ^{
        if (packet.index == self->_selected_audio_track.index) {
            decoder = self.audioDecoder;
        } else if (packet.index == self->_selected_video_track.index) {
            decoder = self.videoDecoder;
        }
    });
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
    __block SGTrack * track = nil;
    SGLockEXE00(self.lock, ^{
        if (decoder.decodable.type == SGMediaTypeAudio) {
            track = self->_selected_audio_track;
        } else if (decoder.decodable.type == SGMediaTypeVideo) {
            track = self->_selected_video_track;
        }
    });
    if (!track) {
        return;
    }
    capacity = [capacity copy];
    SGLockCondEXE11(self.lock, ^BOOL {
        SGCapacity * last = [self.capacityMap objectForKey:track];
        return ![last isEqualToCapacity:capacity];
    }, ^SGBlock {
        [self.capacityMap setObject:capacity forKey:track];
        SGCapacity * audio_capacity = track == self->_selected_audio_track ? capacity : [self.capacityMap objectForKey:self->_selected_audio_track];
        SGCapacity * video_capacity = track == self->_selected_video_track ? capacity : [self.capacityMap objectForKey:self->_selected_video_track];
        self->_audio_finished = audio_capacity.isEmpty && self.packetOutput.state == SGPacketOutputStateFinished;
        self->_video_finished = video_capacity.isEmpty && self.packetOutput.state == SGPacketOutputStateFinished;
        BOOL pause = (audio_capacity.size + video_capacity.size > 15 * 1024 * 1024) || (audio_capacity.isEnough && video_capacity.isEnough);
        return ^{
            if (pause) {
                [self.packetOutput pause];
            } else {
                [self.packetOutput resume];
            }
        };
    }, ^BOOL(SGBlock block) {
        block();
        [self.delegate frameOutput:self didChangeCapacity:[capacity copy] track:track];
        [self setFinishedIfNeeded];
        return YES;
    });
}

@end
