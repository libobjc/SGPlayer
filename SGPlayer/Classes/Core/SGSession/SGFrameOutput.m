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
#import "SGMacro.h"
#import "SGLock.h"

@interface SGFrameOutput () <SGPacketOutputDelegate, SGAsyncDecoderDelegate>

{
    SGFrameOutputState _state;
    int32_t _is_audio_finished;
    int32_t _is_video_finished;
    __strong NSError * _error;
    __strong SGTrack * _selected_audio_track;
    __strong SGTrack * _selected_video_track;
}

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) SGPacketOutput * output;
@property (nonatomic, strong) SGAsyncDecoder * audioDecoder;
@property (nonatomic, strong) SGAsyncDecoder * videoDecoder;
@property (nonatomic, strong) NSMutableDictionary * capacitys;

@end

@implementation SGFrameOutput

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self.lock = [[NSLock alloc] init];
        self.capacitys = [NSMutableDictionary dictionary];
        self.output = [[SGPacketOutput alloc] initWithDemuxable:[asset newDemuxable]];
        self.output.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    SGLockCondEXE10(self.lock, ^BOOL {
        return self->_state != SGFrameOutputStateClosed;
    }, ^SGBlock {
        [self setState:SGFrameOutputStateClosed];
        [self.output close];
        [self.audioDecoder close];
        [self.videoDecoder close];
        return nil;
    });
}

#pragma mark - Mapping

SGGet0Map(CMTime, duration, self.output)
SGGet0Map(NSDictionary *, metadata, self.output)
SGGet0Map(NSArray <SGTrack *> *, tracks, self.output)

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

- (void)setSelectedAudioTrack:(SGTrack *)selectedAudioTrack
{
    NSAssert(selectedAudioTrack, @"Invalid Audio Track");
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
    NSAssert(selectedVideoTrack, @"Invalid Video Track");
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

- (SGCapacity *)capacityWithType:(SGMediaType)type
{
    __block SGCapacity * ret = nil;
    SGLockEXE00(self.lock, ^{
        ret = [[self.capacitys objectForKey:@(type)] copy];
    });
    return ret ? ret : [[SGCapacity alloc] init];
}

- (BOOL)isAudioFinished
{
    __block BOOL ret = NO;
    SGLockEXE00(self.lock, ^{
        ret = self->_is_audio_finished;
    });
    return ret;
}

- (BOOL)isVideoFinished
{
    __block BOOL ret = NO;
    SGLockEXE00(self.lock, ^{
        ret = self->_is_video_finished;
    });
    return ret;
}

- (BOOL)isAudioAvailable
{
    __block BOOL ret = NO;
    SGLockEXE00(self.lock, ^{
        ret = self->_selected_audio_track ? YES : NO;
    });
    return ret;
}

- (BOOL)isVideoAvailable
{
    __block BOOL ret = NO;
    SGLockEXE00(self.lock, ^{
        ret = self->_selected_video_track ? YES : NO;
    });
    return ret;
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
        return [self.output open];
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
        return [self.output resume];
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
        [self.output close];
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

- (BOOL)seekable
{
    return [self.output seekable];
}

- (BOOL)seekToTime:(CMTime)time result:(SGSeekResultBlock)result
{
    SGWeakify(self)
    return [self.output seekToTime:time result:^(CMTime time, NSError * error) {
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
            case SGPacketOutputStateFailed:
                self->_error = [packetOutput.error copy];
                b1 = [self setState:SGFrameOutputStateFailed];
                break;
            default:
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
    SGMediaType type = decoder.decodable.type;
    capacity = [capacity copy];
    SGLockCondEXE11(self.lock, ^BOOL {
        SGCapacity * last = [self.capacitys objectForKey:@(type)];
        return ![last isEqualToCapacity:capacity];
    }, ^SGBlock {
        SGBlock b1 = ^{};
        [self.capacitys setObject:capacity forKey:@(type)];
        SGCapacity * audio = [self.capacitys objectForKey:@(SGMediaTypeAudio)];
        SGCapacity * video = [self.capacitys objectForKey:@(SGMediaTypeVideo)];
        self->_is_audio_finished = (!audio || audio.isEmpty) && self.output.state == SGPacketOutputStateFinished;
        self->_is_video_finished = (!video || video.isEmpty) && self.output.state == SGPacketOutputStateFinished;
        if ((!self->_selected_audio_track || self->_is_audio_finished) &&
            (!self->_selected_video_track || self->_is_video_finished)) {
            b1 = [self setState:SGFrameOutputStateFinished];
        }
        BOOL paused = (audio.size + video.size > 15 * 1024 * 1024) || ((!self->_selected_audio_track || audio.isEnough) && (!self->_selected_video_track || video.isEnough));
        return ^{
            if (paused) {
                [self.output pause];
            } else {
                [self.output resume];
            }
            b1();
        };
    }, ^BOOL(SGBlock block) {
        block();
        [self.delegate frameOutput:self didChangeCapacity:[capacity copy] type:type];
        return YES;
    });
}

@end
