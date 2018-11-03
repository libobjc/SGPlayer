//
//  SGClock.m
//  SGPlayer
//
//  Created by Single on 2018/6/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGClock.h"
#import "SGClock+Internal.h"
#import "SGTime.h"
#import "SGLock.h"

@interface SGClock ()

{
    int32_t _is_paused;
    int32_t _is_audio_finished;
    int32_t _is_video_finished;
    int32_t _nb_audio_update;
    int32_t _nb_video_update;
    CMTime _rate;
    CMTime _time;
    CMTime _last_time;
    CMTime _audio_video_offset;
    double _media_time;
    double _media_time_pause;
    double _invalid_duration;
}

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, weak) id <SGClockDelegate> delegate;

@end

@implementation SGClock

- (instancetype)init
{
    if (self = [super init]) {
        self->_rate = CMTimeMake(1, 1);
        self->_audio_video_offset = kCMTimeZero;
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

- (void)setAudio_video_offset:(CMTime)audio_video_offset
{
    audio_video_offset = CMTimeMinimum(audio_video_offset, CMTimeMake(2, 1));
    audio_video_offset = CMTimeMaximum(audio_video_offset, CMTimeMake(-2, 1));
    SGLockEXE00(self.lock, ^{
        self->_audio_video_offset = audio_video_offset;
    });
}

- (CMTime)audio_video_offset
{
    __block CMTime ret = kCMTimeZero;
    SGLockEXE00(self.lock, ^{
        ret = self->_audio_video_offset;
    });
    return ret;
}

- (CMTime)currentTime
{
    __block CMTime ret = kCMTimeZero;
    SGLockEXE00(self.lock, ^{
        ret = self->_time;
    });
    return ret;
}

- (CMTime)preferredVideoTime
{
    __block CMTime ret = kCMTimeZero;
    SGLockEXE00(self.lock, ^{
        if (self->_media_time == 0) {
            ret = self->_time;
        } else {
            double media_time_current = self->_is_paused ? self->_media_time_pause : CACurrentMediaTime();
            CMTime duration = SGCMTimeMakeWithSeconds(media_time_current - self->_invalid_duration - self->_media_time);
            duration = SGCMTimeMultiply(duration, self->_rate);
            duration = CMTimeMaximum(duration, kCMTimeZero);
            CMTime time = CMTimeAdd(self->_time, self->_nb_audio_update ? self->_audio_video_offset : kCMTimeZero);
            ret = CMTimeAdd(time, duration);
        }
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
    return SGLockCondEXE00(self.lock, ^BOOL{
        return !self->_is_paused;
    }, ^{
        self->_is_paused = 1;
        self->_media_time_pause = CACurrentMediaTime();
    });
}

- (BOOL)resume
{
    return SGLockCondEXE00(self.lock, ^BOOL{
        return self->_is_paused;
    }, ^{
        self->_is_paused = 0;
        self->_invalid_duration += CACurrentMediaTime() - self->_media_time_pause;
    });
}

- (BOOL)flush
{
    return SGLockEXE00(self.lock, ^{
        self->_is_audio_finished = 0;
        self->_is_video_finished = 0;
        self->_nb_audio_update = 0;
        self->_nb_video_update = 0;
        self->_last_time = kCMTimeInvalid;
        self->_time = kCMTimeZero;
        self->_media_time = 0;
    });
}

- (BOOL)setAudioCurrentTime:(CMTime)time
{
    return SGLockEXE10(self.lock, ^SGBlock {
        self->_nb_audio_update += 1;
        return [self setCurrentTime:time];
    });
    return YES;
}

- (BOOL)setVideoCurrentTime:(CMTime)time
{
    return SGLockCondEXE10(self.lock, ^BOOL {
        return !self->_nb_audio_update;
    }, ^SGBlock {
        self->_nb_video_update += 1;
        return [self setCurrentTime:time];
    });
}

- (SGBlock)setCurrentTime:(CMTime)time
{
    CMTime last_time = self->_last_time;
    double media_time = CACurrentMediaTime();
    self->_time = time;
    self->_last_time = self->_time;
    self->_media_time = media_time;
    if (self->_is_paused) {
        self->_media_time_pause = media_time;
    }
    self->_invalid_duration = 0;
    return CMTimeCompare(time, last_time) != 0 ? ^{
        [self.delegate clock:self didChcnageCurrentTime:time];
    } : ^{};
}

@end
