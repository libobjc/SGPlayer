//
//  SGPlaybackAudioRenderer.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPlaybackAudioRenderer.h"
#import "SGAudioStreamPlayer.h"
#import "SGAudioFrame.h"
#import "samplefmt.h"
#import "SGLock.h"

@interface SGPlaybackAudioRenderer () <SGAudioStreamPlayerDelegate>

{
    SGRenderableState _state;
}

@property (nonatomic, strong) SGPlaybackClock * clock;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) SGCapacity * capacity;
@property (nonatomic, strong) SGAudioStreamPlayer * audioPlayer;
@property (nonatomic, strong) SGAudioFrame * frame;
@property (nonatomic, assign) int32_t frame_nb_samples_copied;
@property (nonatomic, assign) int32_t render_nb_samples_copied;
@property (nonatomic, assign) CMTime render_timeStamp;
@property (nonatomic, assign) CMTime render_duration;

@end

@implementation SGPlaybackAudioRenderer

@synthesize object = _object;
@synthesize delegate = _delegate;
@synthesize key = _key;

- (instancetype)initWithClock:(SGPlaybackClock *)clock
{
    if (self = [super init]) {
        self.clock = clock;
        self.rate = CMTimeMake(1, 1);
        self.frame_nb_samples_copied = 0;
        self.render_timeStamp = kCMTimeZero;
        self.render_duration = kCMTimeZero;
        self.coreLock = [[NSLock alloc] init];
        self.audioPlayer = [[SGAudioStreamPlayer alloc] init];
        self.audioPlayer.delegate = self;
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
    SGLockEXE00(self.coreLock, ^{
        ret = self->_state;
    });
    return ret;
}

- (SGCapacity *)capacity
{
    __block SGCapacity * ret = nil;
    SGLockEXE00(self.coreLock, ^{
        ret = [self->_capacity copy];
    });
    return ret ? ret : [[SGCapacity alloc] init];
}

- (void)setVolume:(float)volume
{
    if (_volume != volume) {
        _volume = volume;
        [self.audioPlayer setVolume:volume error:nil];
    }
}

- (void)setRate:(CMTime)rate
{
    if (CMTimeCompare(_rate, rate) != 0) {
        _rate = rate;
        [self.audioPlayer setRate:CMTimeGetSeconds(rate) error:nil];
    }
}

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE10(self.coreLock, ^BOOL {
        return self->_state == SGRenderableStateNone;
    }, ^SGBlock {
        return [self setState:SGRenderableStatePaused];
    });
}

- (BOOL)close
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state != SGRenderableStateClosed;
    }, ^SGBlock {
        [self.frame unlock];
        self.frame = nil;
        self.frame_nb_samples_copied = 0;
        self.render_timeStamp = kCMTimeZero;
        self.render_duration = kCMTimeZero;
        return [self setState:SGRenderableStateClosed];
    }, ^BOOL(SGBlock block) {
        [self.audioPlayer pause];
        block();
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state == SGRenderableStateRendering;
    }, ^SGBlock {
        return [self setState:SGRenderableStatePaused];
    }, ^BOOL(SGBlock block) {
        [self.audioPlayer pause];
        block();
        return YES;
    });
}

- (BOOL)resume
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state == SGRenderableStatePaused;
    }, ^SGBlock {
        return [self setState:SGRenderableStateRendering];
    }, ^BOOL(SGBlock block) {
        [self.audioPlayer play];
        block();
        return YES;
    });
}

- (BOOL)flush
{
    SGLockCondEXE00(self.coreLock, ^BOOL {
        return self->_state == SGRenderableStatePaused || self->_state == SGRenderableStateRendering;
    }, ^{
        [self.frame unlock];
        self.frame = nil;
        self.frame_nb_samples_copied = 0;
        self.render_timeStamp = kCMTimeZero;
        self.render_duration = kCMTimeZero;
    });
    return YES;
}

#pragma mark - SGAudioStreamPlayerDelegate

- (void)audioStreamPlayer:(SGAudioStreamPlayer *)player render:(const AudioTimeStamp *)timeStamp data:(AudioBufferList *)data nb_samples:(uint32_t)nb_samples
{
    [self.coreLock lock];
    self.render_nb_samples_copied = 0;
    self.render_timeStamp = kCMTimeZero;
    self.render_duration = kCMTimeZero;
    if (self->_state != SGRenderableStateRendering) {
        [self.coreLock unlock];
        return;
    }
    uint32_t nb_samples_left = nb_samples;
    while (YES) {
        if (nb_samples_left <= 0) {
            [self.coreLock unlock];
            break;
        }
        if (!self.frame) {
            [self.coreLock unlock];
            SGAudioFrame * frame = [self.delegate renderable:self fetchFrame:nil];
            if (!frame) {
                break;
            }
            [self.coreLock lock];
            self.frame = frame;
        }
        NSAssert(self.frame.format == AV_SAMPLE_FMT_FLTP, @"Invaild audio frame format.");
        int32_t frame_nb_samples_left = self.frame.nb_samples - self.frame_nb_samples_copied;
        int32_t nb_samples_to_copy = MIN(nb_samples_left, frame_nb_samples_left);
        for (int i = 0; i < data->mNumberBuffers && i < self.frame.channels; i++) {
            uint32_t data_offset = self.render_nb_samples_copied * (uint32_t)sizeof(float);
            uint32_t frame_offset = self.frame_nb_samples_copied * (uint32_t)sizeof(float);
            uint32_t size_to_copy = nb_samples_to_copy * (uint32_t)sizeof(float);
            memcpy(data->mBuffers[i].mData + data_offset, self.frame->_data[i] + frame_offset, size_to_copy);
        }
        if (self.render_nb_samples_copied == 0) {
            CMTime duration = CMTimeMultiplyByRatio(self.frame.duration, self.frame_nb_samples_copied, self.frame.nb_samples);
            self.render_timeStamp = CMTimeAdd(self.frame.timeStamp, duration);
        }
        CMTime duration = CMTimeMultiplyByRatio(self.frame.duration, nb_samples_to_copy, self.frame.nb_samples);
        self.render_duration = CMTimeAdd(self.render_duration, duration);
        self.render_nb_samples_copied += nb_samples_to_copy;
        self.frame_nb_samples_copied += nb_samples_to_copy;
        if (self.frame.nb_samples <= self.frame_nb_samples_copied) {
            [self.frame unlock];
            self.frame = nil;
            self.frame_nb_samples_copied = 0;
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
    [self.coreLock lock];
    CMTime rate = self.rate;
    CMTime render_timeStamp = self.render_timeStamp;
    CMTime render_duration = self.render_duration;
    CMTime frame_duration = !self.frame ? kCMTimeZero : CMTimeMultiplyByRatio(self.frame.duration, self.frame.nb_samples - self.frame_nb_samples_copied, self.frame.nb_samples);
    SGBlock clockBlock = ^{};
    if (self->_state == SGRenderableStateRendering && self.render_nb_samples_copied) {
        clockBlock = ^{
            [self.clock updateKeyTime:render_timeStamp duration:render_duration rate:rate];
        };
    }
    SGCapacity * capacity = [[SGCapacity alloc] init];
    capacity.duration = CMTimeAdd(render_duration, frame_duration);
    capacity.size = 0;
    capacity.count = 1;
    SGBlock capacityBlock = ^{};
    if (![capacity isEqualToCapacity:self->_capacity]) {
        self.capacity = capacity;
        capacityBlock = ^{
            [self.delegate renderable:self didChangeCapacity:[capacity copy]];
        };
    }
    [self.coreLock unlock];
    clockBlock();
    capacityBlock();
}

@end
