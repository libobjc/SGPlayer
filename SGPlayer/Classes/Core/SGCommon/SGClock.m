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
    int32_t _nb_audio_update;
    int32_t _nb_video_update;
    CMTime _rate;
    CMTime _time;
    CMTime _duration;
    CMTime _last_time;
    double _media_time;
}

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, weak) id <SGClockDelegate> delegate;

@end

@implementation SGClock

- (instancetype)init
{
    if (self = [super init]) {
        self->_rate = CMTimeMake(1, 1);
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

- (CMTime)currentTime
{
    __block CMTime ret = kCMTimeZero;
    SGLockEXE00(self.lock, ^{
        if (CMTIME_IS_INVALID(self->_duration) ||
            CMTimeCompare(self->_duration, kCMTimeZero) <= 0) {
            ret = self->_time;
        } else {
            double _media_time_current = CACurrentMediaTime();
            CMTime duration = SGCMTimeMakeWithSeconds(_media_time_current - self->_media_time);
            duration = SGCMTimeMultiply(duration, self->_rate);
            duration = CMTimeMinimum(self->_duration, duration);
            ret = CMTimeAdd(self->_time, duration);
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

- (BOOL)flush
{
    return SGLockEXE00(self.lock, ^{
        self->_nb_audio_update = 0;
        self->_nb_video_update = 0;
        self->_last_time = kCMTimeZero;
        self->_time = kCMTimeZero;
        self->_duration = kCMTimeZero;
        self->_media_time = 0;
    });
}

- (BOOL)setAudioTime:(CMTime)time duration:(CMTime)duration
{
    return SGLockEXE10(self.lock, ^SGBlock {
        CMTime last_time = self->_last_time;
        self->_nb_audio_update += 1;
        self->_time = time;
        self->_duration = duration;
        self->_last_time = self->_time;
        self->_media_time = CACurrentMediaTime();
        return CMTimeCompare(time, last_time) != 0 ? ^{
            [self.delegate clock:self didChcnageCurrentTime:time];
        } : ^{};
    });
    return YES;
}

- (BOOL)setVideoTime:(CMTime)time duration:(CMTime)duration
{
    return SGLockCondEXE10(self.lock, ^BOOL {
        return !self->_nb_audio_update;
    }, ^SGBlock {
        CMTime last_time = self->_last_time;
        self->_nb_video_update += 1;
        self->_time = time;
        self->_duration = duration;
        self->_last_time = self->_time;
        self->_media_time = CACurrentMediaTime();
        return CMTimeCompare(time, last_time) != 0 ? ^{
            [self.delegate clock:self didChcnageCurrentTime:time];
        } : ^{};
    });
}

- (BOOL)audioMaster
{
    return SGLockCondEXE00(self.lock, ^BOOL{
        return self->_nb_audio_update && !self->_nb_video_update;
    }, nil);
}

- (BOOL)videoMaster
{
    return SGLockCondEXE00(self.lock, ^BOOL{
        return !self->_nb_audio_update && self->_nb_video_update;
    }, nil);
}

@end
