//
//  SGAudioRenderer.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAudioRenderer.h"
#import "SGRenderer+Internal.h"
#import "SGAudioStreamPlayer.h"
#import "SGAudioFrame.h"
#import "samplefmt.h"
#import "SGLock.h"

@interface SGAudioRenderer () <SGAudioStreamPlayerDelegate>

{
    SGRenderableState _state;
    int32_t _nb_samples_copied_frame;
    int32_t _nb_samples_copied_render;
    double _volume;
    CMTime _rate;
    CMTime _render_time;
    CMTime _render_duration;
    __strong SGCapacity * _capacity;
    __strong SGAudioFrame * _current_frame;
}

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) SGClock * clock;
@property (nonatomic, strong) SGAudioFrameFilter * filter;
@property (nonatomic, strong) SGAudioStreamPlayer * player;

@end

@implementation SGAudioRenderer

@synthesize object = _object;
@synthesize delegate = _delegate;

- (instancetype)initWithClock:(SGClock *)clock
{
    if (self = [super init]) {
        self.clock = clock;
        self->_volume = 1.0f;
        self->_rate = CMTimeMake(1, 1);
        self.lock = [[NSLock alloc] init];
        self.filter = [[SGAudioFrameFilter alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

#pragma mark - Setter & Getter

- (SGBlock)setState:(SGRenderableState)state
{
    if (_state == state) {
        return ^{};
    }
    _state = state;
    return ^{
        [self.delegate renderable:self didChangeState:state];
    };
}

- (SGRenderableState)state
{
    __block SGRenderableState ret = SGRenderableStateNone;
    SGLockEXE00(self.lock, ^{
        ret = self->_state;
    });
    return ret;
}

- (SGCapacity *)capacity
{
    __block SGCapacity * ret = nil;
    SGLockEXE00(self.lock, ^{
        ret = [self->_capacity copy];
    });
    return ret ? ret : [[SGCapacity alloc] init];
}

- (void)setRate:(CMTime)rate
{
    SGLockCondEXE11(self.lock, ^BOOL {
        return CMTimeCompare(self->_rate, rate) != 0;
    }, ^SGBlock {
        self->_rate = rate;
        return nil;
    }, ^BOOL(SGBlock block) {
        [self.player setRate:CMTimeGetSeconds(rate) error:nil];
        return YES;
    });
}

- (CMTime)rate
{
    __block CMTime ret = CMTimeMake(1, 1);
    SGLockEXE00(self.lock, ^{
        ret = self->_rate;
    });
    return ret;
}

- (void)setVolume:(double)volume
{
    SGLockCondEXE11(self.lock, ^BOOL {
        return self->_volume != volume;
    }, ^SGBlock {
        self->_volume = volume;
        return nil;
    }, ^BOOL(SGBlock block) {
        [self.player setVolume:volume error:nil];
        return YES;
    });
}

- (double)volume
{
    __block double ret = 1.0f;
    SGLockEXE00(self.lock, ^{
        ret = self->_volume;
    });
    return ret;
}

#pragma mark - Interface

- (BOOL)open
{
    __block float volume = 1.0f;
    __block CMTime rate = CMTimeMake(1, 1);
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state == SGRenderableStateNone;
    }, ^SGBlock {
        volume = self->_volume;
        rate = self->_rate;
        return [self setState:SGRenderableStatePaused];
    }, ^BOOL(SGBlock block) {
        block();
        self.player = [[SGAudioStreamPlayer alloc] init];
        self.player.delegate = self;
        [self.player setVolume:volume error:nil];
        [self.player setRate:CMTimeGetSeconds(rate) error:nil];
        return YES;
    });
}

- (BOOL)close
{
    return SGLockEXE11(self.lock, ^SGBlock {
        self->_nb_samples_copied_frame = 0;
        self->_nb_samples_copied_render = 0;
        self->_render_time = kCMTimeZero;
        self->_render_duration = kCMTimeZero;
        self->_capacity = nil;
        [self->_current_frame unlock];
        self->_current_frame = nil;
        return [self setState:SGRenderableStateNone];
    }, ^BOOL(SGBlock block) {
        [self.player pause];
        self.player = nil;
        block();
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state == SGRenderableStateRendering || self->_state == SGRenderableStateFinished;
    }, ^SGBlock {
        return [self setState:SGRenderableStatePaused];
    }, ^BOOL(SGBlock block) {
        [self.player pause];
        block();
        return YES;
    });
}

- (BOOL)resume
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state == SGRenderableStatePaused || self->_state == SGRenderableStateFinished;
    }, ^SGBlock {
        return [self setState:SGRenderableStateRendering];
    }, ^BOOL(SGBlock block) {
        [self.player play];
        block();
        return YES;
    });
}

- (BOOL)finish
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state == SGRenderableStateRendering || self->_state == SGRenderableStatePaused;
    }, ^SGBlock {
        return [self setState:SGRenderableStateFinished];
    }, ^BOOL(SGBlock block) {
        [self.player pause];
        block();
        return YES;
    });
}

- (BOOL)flush
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state == SGRenderableStatePaused || self->_state == SGRenderableStateRendering || self->_state == SGRenderableStateFinished;
    }, ^SGBlock {
        [self->_current_frame unlock];
        self->_current_frame = nil;
        self->_nb_samples_copied_frame = 0;
        self->_nb_samples_copied_render = 0;
        self->_render_time = kCMTimeZero;
        self->_render_duration = kCMTimeZero;
        return ^{};
    }, ^BOOL(SGBlock block) {
        [self.player flush];
        block();
        return YES;
    });
}

#pragma mark - SGAudioStreamPlayerDelegate

- (void)audioStreamPlayer:(SGAudioStreamPlayer *)player render:(const AudioTimeStamp *)timeStamp data:(AudioBufferList *)data nb_samples:(uint32_t)nb_samples
{
    [self.lock lock];
    self->_nb_samples_copied_render = 0;
    self->_render_time = kCMTimeZero;
    self->_render_duration = kCMTimeZero;
    if (self->_state != SGRenderableStateRendering) {
        [self.lock unlock];
        return;
    }
    uint32_t nb_samples_left = nb_samples;
    while (YES) {
        if (nb_samples_left <= 0) {
            [self.lock unlock];
            break;
        }
        if (!self->_current_frame) {
            [self.lock unlock];
            SGAudioFrame * frame = [self.delegate renderable:self fetchFrame:nil];
            if (!frame) {
                break;
            }
            [self.lock lock];
            self->_current_frame = frame;
        }
        NSAssert(self->_current_frame.format == AV_SAMPLE_FMT_FLTP, @"Invaild audio frame format.");
        int32_t frame_nb_samples_left = self->_current_frame.nb_samples - self->_nb_samples_copied_frame;
        int32_t nb_samples_to_copy = MIN(nb_samples_left, frame_nb_samples_left);
        for (int i = 0; i < data->mNumberBuffers && i < self->_current_frame.channels; i++) {
            uint32_t data_offset = self->_nb_samples_copied_render * (uint32_t)sizeof(float);
            uint32_t frame_offset = self->_nb_samples_copied_frame * (uint32_t)sizeof(float);
            uint32_t size_to_copy = nb_samples_to_copy * (uint32_t)sizeof(float);
            memcpy(data->mBuffers[i].mData + data_offset, self->_current_frame->_data[i] + frame_offset, size_to_copy);
        }
        if (self->_nb_samples_copied_render == 0) {
            CMTime duration = CMTimeMultiplyByRatio(self->_current_frame.duration, self->_nb_samples_copied_frame, self->_current_frame.nb_samples);
            self->_render_time = CMTimeAdd(self->_current_frame.timeStamp, duration);
        }
        CMTime duration = CMTimeMultiplyByRatio(self->_current_frame.duration, nb_samples_to_copy, self->_current_frame.nb_samples);
        self->_render_duration = CMTimeAdd(self->_render_duration, duration);
        self->_nb_samples_copied_render += nb_samples_to_copy;
        self->_nb_samples_copied_frame += nb_samples_to_copy;
        if (self->_current_frame.nb_samples <= self->_nb_samples_copied_frame) {
            [self->_current_frame unlock];
            self->_current_frame = nil;
            self->_nb_samples_copied_frame = 0;
        }
        nb_samples_left -= nb_samples_to_copy;
    }
    uint32_t nb_samples_copied = nb_samples - nb_samples_left;
    for (int i = 0; i < data->mNumberBuffers; i++) {
        uint32_t size_copied = nb_samples_copied * (uint32_t)sizeof(float);
        uint32_t size_left = data->mBuffers[i].mDataByteSize - size_copied;
        if (size_left > 0) {
            memset(data->mBuffers[i].mData + size_copied, 0, size_left);
        }
    }
}

- (void)audioStreamPlayer:(SGAudioStreamPlayer *)player postRender:(const AudioTimeStamp *)timestamp
{
    [self.lock lock];
    CMTime render_timeStamp = self->_render_time;
    CMTime render_duration = SGCMTimeMultiply(self->_render_duration, self->_rate);
    CMTime frame_duration = !self->_current_frame ? kCMTimeZero : CMTimeMultiplyByRatio(self->_current_frame.duration, self->_current_frame.nb_samples - self->_nb_samples_copied_frame, self->_current_frame.nb_samples);
    SGBlock clockBlock = ^{};
    if (self->_state == SGRenderableStateRendering) {
        if (self->_nb_samples_copied_render) {
            clockBlock = ^{
                [self.clock setAudioCurrentTime:render_timeStamp];
            };
        } else {
            clockBlock = ^{
                [self.clock markAsAudioStalled];
            };
        }
    }
    SGCapacity * capacity = [[SGCapacity alloc] init];
    capacity.duration = CMTimeAdd(render_duration, frame_duration);
    SGBlock capacityBlock = ^{};
    if (![capacity isEqualToCapacity:self->_capacity]) {
        self->_capacity = capacity;
        capacityBlock = ^{
            [self.delegate renderable:self didChangeCapacity:[capacity copy]];
        };
    }
    [self.lock unlock];
    clockBlock();
    capacityBlock();
}

@end
