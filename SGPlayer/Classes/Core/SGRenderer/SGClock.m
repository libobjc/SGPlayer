//
//  SGClock.m
//  SGPlayer
//
//  Created by Single on 2018/6/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGClock.h"
#import "SGClock+Internal.h"
#import <QuartzCore/QuartzCore.h>
#import "SGLock.h"

@interface SGClock ()

{
    int32_t _is_paused;
    int32_t _is_audio_stalled;
    int32_t _is_audio_finished;
    int32_t _is_video_finished;
    int32_t _nb_set_audio_time;
    int32_t _nb_set_video_time;
    CMTime _rate;
    CMTime _audio_time;
    CMTime _video_time;
    CMTime _current_time;
    CMTime _video_advanced_duration;
    double _audio_media_time;
    double _video_media_time;
    double _pause_media_time;
    double _invalid_duration;
}

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, weak) id<SGClockDelegate> delegate;

@end

@implementation SGClock

- (instancetype)init
{
    if (self = [super init]) {
        self->_rate = CMTimeMake(1, 1);
        self->_video_advanced_duration = kCMTimeZero;
        self.lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)setRate:(CMTime)rate
{
    SGLockEXE00(self.lock, ^{
        self->_rate = rate;
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

- (void)setVideoAdvancedDuration:(CMTime)videoAdvancedDuration
{
    videoAdvancedDuration = CMTimeMinimum(videoAdvancedDuration, CMTimeMake(2, 1));
    videoAdvancedDuration = CMTimeMaximum(videoAdvancedDuration, CMTimeMake(-2, 1));
    SGLockEXE00(self.lock, ^{
        self->_video_advanced_duration = videoAdvancedDuration;
    });
}

- (CMTime)videoAdvancedDuration
{
    __block CMTime ret = kCMTimeZero;
    SGLockEXE00(self.lock, ^{
        ret = self->_video_advanced_duration;
    });
    return ret;
}

- (CMTime)currentTime
{
    __block CMTime ret = kCMTimeZero;
    SGLockEXE00(self.lock, ^{
        ret = self->_current_time;
    });
    return ret;
}

- (BOOL)open
{
    return [self flush];
}

- (BOOL)close
{
    return [self flush];
}

- (BOOL)pause
{
    return SGLockCondEXE00(self.lock, ^BOOL {
        return !self->_is_paused;
    }, ^{
        self->_is_paused = 1;
        self->_pause_media_time = CACurrentMediaTime();
    });
}

- (BOOL)resume
{
    return SGLockCondEXE00(self.lock, ^BOOL {
        return self->_is_paused;
    }, ^{
        self->_is_paused = 0;
        self->_invalid_duration += CACurrentMediaTime() - self->_pause_media_time;
    });
}

- (BOOL)flush
{
    return SGLockEXE00(self.lock, ^{
        self->_is_audio_stalled = 0;
        self->_is_audio_finished = 0;
        self->_is_video_finished = 0;
        self->_nb_set_audio_time = 0;
        self->_nb_set_video_time = 0;
        self->_audio_time = kCMTimeZero;
        self->_video_time = kCMTimeZero;
        self->_current_time = kCMTimeZero;
        self->_audio_media_time = 0;
        self->_video_media_time = 0;
    });
}

- (BOOL)setAudioCurrentTime:(CMTime)time
{
    return SGLockEXE10(self.lock, ^SGBlock {
        self->_nb_set_audio_time += 1;
        self->_audio_time = time;
        self->_audio_media_time = CACurrentMediaTime();
        self->_is_audio_stalled = 0;
        return [self setCurrentTime:self->_audio_time mediaTime:self->_audio_media_time];
    });
    return YES;
}

- (BOOL)setVideoCurrentTime:(CMTime)time
{
    return SGLockEXE10(self.lock, ^SGBlock {
        self->_nb_set_video_time += 1;
        self->_video_time = time;
        self->_video_media_time = CACurrentMediaTime();
        if (!self->_nb_set_audio_time || self->_is_audio_stalled) {
            return [self setCurrentTime:self->_video_time mediaTime:self->_video_media_time];
        }
        return ^{};
    });
}

- (SGBlock)setCurrentTime:(CMTime)time mediaTime:(double)mediaTime
{
    CMTime current_time = self->_current_time;
    self->_current_time = time;
    if (self->_is_paused) {
        self->_pause_media_time = mediaTime;
    }
    self->_invalid_duration = 0;
    return CMTimeCompare(time, current_time) != 0 ? ^{
        [self.delegate clock:self didChcnageCurrentTime:time];
    } : ^{};
}

- (BOOL)markAsAudioStalled
{
    return SGLockEXE00(self.lock, ^{
        self->_is_audio_stalled = 1;
    });
}

- (BOOL)preferredVideoTime:(CMTime *)time advanced:(CMTime *)advanced
{
    __block CMTime ret_time = kCMTimeZero;
    __block CMTime ret_advanced = kCMTimeZero;
    SGLockEXE00(self.lock, ^{
        double current_media_time = self->_is_paused ? self->_pause_media_time : CACurrentMediaTime();
        if (self->_nb_set_audio_time && !self->_is_audio_stalled) {
            CMTime duration = SGCMTimeMakeWithSeconds(current_media_time - self->_audio_media_time - self->_invalid_duration);
            duration = SGCMTimeMultiply(duration, self->_rate);
            duration = CMTimeMaximum(duration, kCMTimeZero);
            ret_time = CMTimeAdd(self->_audio_time, duration);
            ret_advanced = self->_video_advanced_duration;
        } else if (self->_nb_set_video_time || self->_is_audio_stalled) {
            CMTime duration = SGCMTimeMakeWithSeconds(current_media_time - self->_video_media_time - self->_invalid_duration);
            duration = SGCMTimeMultiply(duration, self->_rate);
            duration = CMTimeMaximum(duration, kCMTimeZero);
            ret_time = CMTimeAdd(self->_video_time, duration);
        }
    });
    * time = ret_time;
    * advanced = ret_advanced;
    return YES;
}

@end
