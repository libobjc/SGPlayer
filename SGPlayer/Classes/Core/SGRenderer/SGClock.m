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
    NSLock *_lock;
    
    BOOL _paused;
    BOOL _audioStalled;
    BOOL _audioFinished;
    BOOL _videoFinished;
    
    CMTime _rate;
    CMTime _currentTime;
    CMTime _videoAdvancedDuration;
    
    CMTime _audioTime;
    CMTime _videoTime;
    long _audioSetTimes;
    long _videoSetTimes;
    
    double _audioMediaTime;
    double _videoMediaTime;
    double _pauseMediaTime;
    double _invalidMediaInterval;
}

@end

@implementation SGClock

- (instancetype)init
{
    if (self = [super init]) {
        self->_rate = CMTimeMake(1, 1);
        self->_videoAdvancedDuration = kCMTimeZero;
        self->_lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)setRate:(CMTime)rate
{
    SGLockEXE00(self->_lock, ^{
        self->_rate = rate;
    });
}

- (CMTime)rate
{
    __block CMTime ret = CMTimeMake(1, 1);
    SGLockEXE00(self->_lock, ^{
        ret = self->_rate;
    });
    return ret;
}

- (void)setVideoAdvancedDuration:(CMTime)videoAdvancedDuration
{
    videoAdvancedDuration = CMTimeMinimum(videoAdvancedDuration, CMTimeMake(2, 1));
    videoAdvancedDuration = CMTimeMaximum(videoAdvancedDuration, CMTimeMake(-2, 1));
    SGLockEXE00(self->_lock, ^{
        self->_videoAdvancedDuration = videoAdvancedDuration;
    });
}

- (CMTime)videoAdvancedDuration
{
    __block CMTime ret = kCMTimeZero;
    SGLockEXE00(self->_lock, ^{
        ret = self->_videoAdvancedDuration;
    });
    return ret;
}

- (CMTime)currentTime
{
    __block CMTime ret = kCMTimeZero;
    SGLockEXE00(self->_lock, ^{
        ret = self->_currentTime;
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
    return SGLockCondEXE00(self->_lock, ^BOOL {
        return !self->_paused;
    }, ^{
        self->_paused = YES;
        self->_pauseMediaTime = CACurrentMediaTime();
    });
}

- (BOOL)resume
{
    return SGLockCondEXE00(self->_lock, ^BOOL {
        return self->_paused;
    }, ^{
        self->_paused = NO;
        self->_invalidMediaInterval += CACurrentMediaTime() - self->_pauseMediaTime;
    });
}

- (BOOL)flush
{
    return SGLockEXE00(self->_lock, ^{
        self->_audioStalled = 0;
        self->_audioFinished = 0;
        self->_videoFinished = 0;
        self->_audioSetTimes = 0;
        self->_videoSetTimes = 0;
        self->_audioTime = kCMTimeZero;
        self->_videoTime = kCMTimeZero;
        self->_currentTime = kCMTimeZero;
        self->_audioMediaTime = 0;
        self->_videoMediaTime = 0;
    });
}

- (BOOL)setAudioCurrentTime:(CMTime)time
{
    return SGLockEXE10(self->_lock, ^SGBlock {
        self->_audioSetTimes += 1;
        self->_audioTime = time;
        self->_audioMediaTime = CACurrentMediaTime();
        self->_audioStalled = 0;
        return [self setCurrentTime:self->_audioTime mediaTime:self->_audioMediaTime];
    });
    return YES;
}

- (BOOL)setVideoCurrentTime:(CMTime)time
{
    return SGLockEXE10(self->_lock, ^SGBlock {
        self->_videoSetTimes += 1;
        self->_videoTime = time;
        self->_videoMediaTime = CACurrentMediaTime();
        if (!self->_audioSetTimes || self->_audioStalled) {
            return [self setCurrentTime:self->_videoTime mediaTime:self->_videoMediaTime];
        }
        return ^{};
    });
}

- (SGBlock)setCurrentTime:(CMTime)time mediaTime:(double)mediaTime
{
    CMTime current_time = self->_currentTime;
    self->_currentTime = time;
    if (self->_paused) {
        self->_pauseMediaTime = mediaTime;
    }
    self->_invalidMediaInterval = 0;
    return CMTimeCompare(time, current_time) != 0 ? ^{
        [self.delegate clock:self didChcnageCurrentTime:time];
    } : ^{};
}

- (BOOL)markAsAudioStalled
{
    return SGLockEXE00(self->_lock, ^{
        self->_audioStalled = 1;
    });
}

- (BOOL)preferredVideoTime:(CMTime *)time advanced:(CMTime *)advanced
{
    return SGLockCondEXE00(self->_lock, ^BOOL {
        double current_media_time = self->_paused ? self->_pauseMediaTime : CACurrentMediaTime();
        if (self->_audioSetTimes && !self->_audioStalled) {
            CMTime duration = SGCMTimeMakeWithSeconds(current_media_time - self->_audioMediaTime - self->_invalidMediaInterval);
            duration = SGCMTimeMultiply(duration, self->_rate);
            duration = CMTimeMaximum(duration, kCMTimeZero);
            *time = CMTimeAdd(self->_audioTime, duration);
            *advanced = self->_videoAdvancedDuration;
        } else if (self->_videoSetTimes || self->_audioStalled) {
            CMTime duration = SGCMTimeMakeWithSeconds(current_media_time - self->_videoMediaTime - self->_invalidMediaInterval);
            duration = SGCMTimeMultiply(duration, self->_rate);
            duration = CMTimeMaximum(duration, kCMTimeZero);
            *time = CMTimeAdd(self->_videoTime, duration);
            *advanced = kCMTimeZero;
        } else {
            *time = kCMTimeZero;
            *advanced = kCMTimeZero;
        }
        return YES;
    }, nil);
}

@end
