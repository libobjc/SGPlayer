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
@property (nonatomic, strong) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) SGAudioStreamPlayer * audioPlayer;

@property (nonatomic, strong) SGAudioFrame * frame;
@property (nonatomic, assign) int32_t frame_nb_samples_copied;
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
        self.delay = CMTimeMake(0, 1);
        self.frame_nb_samples_copied = 0;
        self.render_timeStamp = kCMTimeZero;
        self.render_duration = kCMTimeZero;
        self.coreLock = [[NSLock alloc] init];
        self.delegateQueue = dispatch_queue_create("SGPlaybackAudioRenderer-delegateQueue", DISPATCH_QUEUE_SERIAL);
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
    if (self->_state != SGRenderableStateRendering) {
        [self.coreLock unlock];
        return;
    }
    uint32_t nb_samples_copied = 0;
    while (nb_samples > 0) {
        if (!self.frame) {
            [self.coreLock unlock];
            SGAudioFrame * frame = [self.delegate renderable:self fetchFrame:nil];
            if (!frame) {
                return;
            }
            [self.coreLock lock];
            self.frame = frame;
        }
        NSAssert(self.frame.format == AV_SAMPLE_FMT_FLTP, @"Invaild audio frame format.");
        int32_t nb_samples_left = self.frame.nb_samples - self.frame_nb_samples_copied;
        int32_t nb_samples_to_copy = MIN(nb_samples, nb_samples_left);
        for (int i = 0; i < data->mNumberBuffers && i < self.frame.channels; i++) {
            uint32_t data_offset = nb_samples_copied * (uint32_t)sizeof(float);
            uint32_t frame_offset = self.frame_nb_samples_copied * (uint32_t)sizeof(float);
            uint32_t size_to_copy = nb_samples_to_copy * (uint32_t)sizeof(float);
            memcpy(data->mBuffers[i].mData + data_offset, self.frame->_data[i] + frame_offset, size_to_copy);
        }
        if (nb_samples_copied == 0) {
            CMTime duration = CMTimeMultiplyByRatio(self.frame.duration, self.frame_nb_samples_copied, self.frame.nb_samples);
            self.render_timeStamp = CMTimeAdd(self.frame.timeStamp, duration);
            self.render_duration = kCMTimeZero;
        }
        CMTime duration = CMTimeMultiplyByRatio(self.frame.duration, nb_samples_to_copy, self.frame.nb_samples);
        self.render_duration = CMTimeAdd(self.render_duration, duration);
        nb_samples -= nb_samples_to_copy;
        nb_samples_copied += nb_samples_to_copy;
        self.frame_nb_samples_copied += nb_samples_to_copy;
        if (self.frame.nb_samples <= self.frame_nb_samples_copied) {
            [self.frame unlock];
            self.frame = nil;
            self.frame_nb_samples_copied = 0;
        }
    }
    [self.coreLock unlock];
}

- (void)audioStreamPlayer:(SGAudioStreamPlayer *)player postRender:(const AudioTimeStamp *)timestamp
{
    [self.coreLock lock];
    CMTime render_timeStamp = self.render_timeStamp;
    CMTime render_duration = self.render_duration;
    CMTime rate = self.rate;
    CMTime delay = self.delay;
    [self.coreLock unlock];
    dispatch_block_t block = ^{
        [self.clock updateKeyTime:render_timeStamp duration:render_duration rate:rate];
    };
    if (CMTimeCompare(delay, kCMTimeZero) > 0) {
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CMTimeGetSeconds(delay) * NSEC_PER_SEC));
        dispatch_after(time, self.delegateQueue, block);
    } else {
        block();
    }
}

@end
