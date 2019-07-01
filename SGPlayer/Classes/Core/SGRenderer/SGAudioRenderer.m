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
#import "SGOptions.h"
#import "SGFFmpeg.h"
#import "SGLock.h"

@interface SGAudioRenderer () <SGAudioStreamPlayerDelegate>

{
    struct {
        SGRenderableState state;
        CMTime renderTime;
        CMTime renderDuration;
        int frameCopiedSamples;
        int renderCopiedSamples;
    } _flags;
    SGCapacity _capacity;
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) SGClock *clock;
@property (nonatomic, strong, readonly) SGAudioFrame *currentFrame;
@property (nonatomic, strong, readonly) SGAudioStreamPlayer *player;

@end

@implementation SGAudioRenderer

@synthesize rate = _rate;
@synthesize volume = _volume;
@synthesize options = _options;
@synthesize delegate = _delegate;
@synthesize descriptor = _descriptor;

- (instancetype)init
{
    NSAssert(NO, @"Invalid Function.");
    return nil;
}

- (instancetype)initWithClock:(SGClock *)clock
{
    if (self = [super init]) {
        self->_clock = clock;
        self->_rate = 1.0;
        self->_volume = 1.0;
        self->_lock = [[NSLock alloc] init];
        self->_capacity = SGCapacityCreate();
        self->_options = [SGOptions sharedOptions].renderer.copy;
        self->_descriptor = [[SGAudioDescriptor alloc] init];
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
    if (self->_flags.state == state) {
        return ^{};
    }
    self->_flags.state = state;
    return ^{
        [self.delegate renderable:self didChangeState:state];
    };
}

- (SGRenderableState)state
{
    __block SGRenderableState ret = SGRenderableStateNone;
    SGLockEXE00(self->_lock, ^{
        ret = self->_flags.state;
    });
    return ret;
}

- (SGCapacity)capacity
{
    __block SGCapacity ret;
    SGLockEXE00(self->_lock, ^{
        ret = self->_capacity;
    });
    return ret;
}

- (void)setRate:(Float64)rate
{
    SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_rate != rate;
    }, ^SGBlock {
        self->_rate = rate;
        return nil;
    }, ^BOOL(SGBlock block) {
        [self->_player setRate:rate error:nil];
        return YES;
    });
}

- (Float64)rate
{
    __block Float64 ret = 1.0;
    SGLockEXE00(self->_lock, ^{
        ret = self->_rate;
    });
    return ret;
}

- (void)setVolume:(Float64)volume
{
    SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_volume != volume;
    }, ^SGBlock {
        self->_volume = volume;
        return nil;
    }, ^BOOL(SGBlock block) {
        [self->_player setVolume:volume error:nil];
        return YES;
    });
}

- (Float64)volume
{
    __block Float64 ret = 1.0f;
    SGLockEXE00(self->_lock, ^{
        ret = self->_volume;
    });
    return ret;
}

- (SGAudioDescriptor *)descriptor
{
    __block SGAudioDescriptor *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = self->_descriptor;
    });
    return ret;
}

#pragma mark - Interface

- (BOOL)open
{
    __block Float64 rate = 1.0;
    __block Float64 volume = 1.0;
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == SGRenderableStateNone;
    }, ^SGBlock {
        rate = self->_rate;
        volume = self->_volume;
        return [self setState:SGRenderableStatePaused];
    }, ^BOOL(SGBlock block) {
        block();
        self->_player = [[SGAudioStreamPlayer alloc] init];
        self->_player.delegate = self;
        [self->_player setVolume:volume error:nil];
        [self->_player setRate:rate error:nil];
        return YES;
    });
}

- (BOOL)close
{
    return SGLockEXE11(self->_lock, ^SGBlock {
        self->_flags.frameCopiedSamples = 0;
        self->_flags.renderCopiedSamples = 0;
        self->_flags.renderTime = kCMTimeZero;
        self->_flags.renderDuration = kCMTimeZero;
        self->_capacity = SGCapacityCreate();
        [self->_currentFrame unlock];
        self->_currentFrame = nil;
        return [self setState:SGRenderableStateNone];
    }, ^BOOL(SGBlock block) {
        [self->_player pause];
        self->_player = nil;
        block();
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == SGRenderableStateRendering || self->_flags.state == SGRenderableStateFinished;
    }, ^SGBlock {
        return [self setState:SGRenderableStatePaused];
    }, ^BOOL(SGBlock block) {
        [self->_player pause];
        block();
        return YES;
    });
}

- (BOOL)resume
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == SGRenderableStatePaused || self->_flags.state == SGRenderableStateFinished;
    }, ^SGBlock {
        return [self setState:SGRenderableStateRendering];
    }, ^BOOL(SGBlock block) {
        [self->_player play];
        block();
        return YES;
    });
}

- (BOOL)flush
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == SGRenderableStatePaused || self->_flags.state == SGRenderableStateRendering || self->_flags.state == SGRenderableStateFinished;
    }, ^SGBlock {
        [self->_currentFrame unlock];
        self->_currentFrame = nil;
        self->_flags.frameCopiedSamples = 0;
        self->_flags.renderCopiedSamples = 0;
        self->_flags.renderTime = kCMTimeZero;
        self->_flags.renderDuration = kCMTimeZero;
        return ^{};
    }, ^BOOL(SGBlock block) {
        [self->_player flush];
        block();
        return YES;
    });
}

- (BOOL)finish
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == SGRenderableStateRendering || self->_flags.state == SGRenderableStatePaused;
    }, ^SGBlock {
        return [self setState:SGRenderableStateFinished];
    }, ^BOOL(SGBlock block) {
        [self->_player pause];
        block();
        return YES;
    });
}


#pragma mark - SGAudioStreamPlayerDelegate

- (void)audioStreamPlayer:(SGAudioStreamPlayer *)player render:(const AudioTimeStamp *)timeStamp data:(AudioBufferList *)data nb_samples:(UInt32)nb_samples
{
    [self->_lock lock];
    self->_flags.renderCopiedSamples = 0;
    self->_flags.renderTime = kCMTimeZero;
    self->_flags.renderDuration = kCMTimeZero;
    if (self->_flags.state != SGRenderableStateRendering) {
        [self->_lock unlock];
        return;
    }
    UInt32 nb_samples_left = nb_samples;
    while (YES) {
        if (nb_samples_left <= 0) {
            [self->_lock unlock];
            break;
        }
        if (!self->_currentFrame) {
            [self->_lock unlock];
            SGAudioFrame *frame = [self.delegate renderable:self fetchFrame:nil];
            if (!frame) {
                break;
            }
            [self->_lock lock];
            self->_currentFrame = frame;
        }
        SGAudioDescriptor *descriptor = self->_currentFrame.descriptor;
        NSAssert(descriptor.format == AV_SAMPLE_FMT_FLTP, @"Invaild audio frame format.");
        UInt32 frame_nb_samples_left = self->_currentFrame.numberOfSamples - self->_flags.frameCopiedSamples;
        UInt32 nb_samples_to_copy = MIN(nb_samples_left, frame_nb_samples_left);
        for (int i = 0; i < data->mNumberBuffers && i < descriptor.numberOfChannels; i++) {
            UInt32 data_offset = self->_flags.renderCopiedSamples * (UInt32)sizeof(float);
            UInt32 frame_offset = self->_flags.frameCopiedSamples * (UInt32)sizeof(float);
            UInt32 size_to_copy = nb_samples_to_copy * (UInt32)sizeof(float);
            memcpy(data->mBuffers[i].mData + data_offset, self->_currentFrame.data[i] + frame_offset, size_to_copy);
        }
        if (self->_flags.renderCopiedSamples == 0) {
            CMTime duration = CMTimeMultiplyByRatio(self->_currentFrame.duration, self->_flags.frameCopiedSamples, self->_currentFrame.numberOfSamples);
            self->_flags.renderTime = CMTimeAdd(self->_currentFrame.timeStamp, duration);
        }
        CMTime duration = CMTimeMultiplyByRatio(self->_currentFrame.duration, nb_samples_to_copy, self->_currentFrame.numberOfSamples);
        self->_flags.renderDuration = CMTimeAdd(self->_flags.renderDuration, duration);
        self->_flags.renderCopiedSamples += nb_samples_to_copy;
        self->_flags.frameCopiedSamples += nb_samples_to_copy;
        if (self->_currentFrame.numberOfSamples <= self->_flags.frameCopiedSamples) {
            [self->_currentFrame unlock];
            self->_currentFrame = nil;
            self->_flags.frameCopiedSamples = 0;
        }
        nb_samples_left -= nb_samples_to_copy;
    }
    UInt32 nb_samples_copied = nb_samples - nb_samples_left;
    for (int i = 0; i < data->mNumberBuffers; i++) {
        UInt32 size_copied = nb_samples_copied * (UInt32)sizeof(float);
        UInt32 size_left = data->mBuffers[i].mDataByteSize - size_copied;
        if (size_left > 0) {
            memset(data->mBuffers[i].mData + size_copied, 0, size_left);
        }
    }
}

- (void)audioStreamPlayer:(SGAudioStreamPlayer *)player postRender:(const AudioTimeStamp *)timestamp
{
    [self->_lock lock];
    CMTime renderTime = self->_flags.renderTime;
    CMTime renderDuration = CMTimeMultiplyByFloat64(self->_flags.renderDuration, self->_rate);
    CMTime frameDuration = !self->_currentFrame ? kCMTimeZero : CMTimeMultiplyByRatio(self->_currentFrame.duration, self->_currentFrame.numberOfSamples - self->_flags.frameCopiedSamples, self->_currentFrame.numberOfSamples);
    SGBlock clockBlock = ^{};
    if (self->_flags.state == SGRenderableStateRendering) {
        if (self->_flags.renderCopiedSamples) {
            clockBlock = ^{
                [self->_clock setAudioTime:renderTime running:YES];
            };
        } else {
            clockBlock = ^{
                [self->_clock setAudioTime:kCMTimeInvalid running:NO];
            };
        }
    }
    SGCapacity capacity = SGCapacityCreate();
    capacity.duration = CMTimeAdd(renderDuration, frameDuration);
    SGBlock capacityBlock = ^{};
    if (!SGCapacityIsEqual(self->_capacity, capacity)) {
        self->_capacity = capacity;
        capacityBlock = ^{
            [self.delegate renderable:self didChangeCapacity:capacity];
        };
    }
    [self->_lock unlock];
    clockBlock();
    capacityBlock();
}

@end
