//
//  SGClock.m
//  SGPlayer
//
//  Created by Single on 2018/6/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGClock.h"
#import "SGClock+Internal.h"
#import "SGLock.h"
#import "SGTime.h"

@interface SGClock ()

{
    BOOL _audioRunning;
    BOOL _videoRunning;
    CMClockRef _masterClock;
    CMTimebaseRef _audioTimebase;
    CMTimebaseRef _videoTimebase;
    CMTimebaseRef _playbackTimebase;
}

@property (nonatomic, strong, readonly) NSLock *lock;

@end

@implementation SGClock

@synthesize rate = _rate;

- (instancetype)init
{
    if (self = [super init]) {
        self->_rate = 1.0;
        self->_lock = [[NSLock alloc] init];
        self->_masterClock = CMClockGetHostTimeClock();
    }
    return self;
}

- (void)setRate:(Float64)rate
{
    SGLockEXE00(self->_lock, ^{
        self->_rate = rate;
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

- (CMTime)currentTime
{
    __block CMTime ret = kCMTimeZero;
    SGLockEXE00(self->_lock, ^{
        if (self->_audioRunning) {
            ret = CMTimebaseGetTime(self->_audioTimebase);
        } else {
            ret = CMTimebaseGetTime(self->_videoTimebase);
        }
    });
    return ret;
}

- (void)setAudioTime:(CMTime)time running:(BOOL)running
{
    SGLockEXE00(self->_lock, ^{
        if (CMTIME_IS_NUMERIC(time)) {
            if (self->_audioRunning != running || self->_videoRunning == NO) {
                self->_audioRunning = running;
                self->_videoRunning = YES;
                CMTime playbackTime = CMTimebaseGetTime(self->_playbackTimebase);
                CMTimebaseSetRateAndAnchorTime(self->_videoTimebase, 1.0, time, playbackTime);
                CMTimebaseSetRateAndAnchorTime(self->_audioTimebase, running ? 1.0 : 0.0, time, playbackTime);
            } else {
                CMTimebaseSetTime(self->_audioTimebase, time);
                CMTimebaseSetTime(self->_videoTimebase, time);
            }
            [self.delegate clock:self didChangeCurrentTime:time];
        } else if (self->_audioRunning != running) {
            self->_audioRunning = running;
            CMTimebaseSetRate(self->_audioTimebase, running ? 1.0 : 0.0);
        }
    });
}

- (void)setVideoTime:(CMTime)time
{
    SGLockCondEXE00(self->_lock, ^BOOL {
        return self->_audioRunning == NO && CMTIME_IS_NUMERIC(time);
    }, ^{
        if (self->_videoRunning == NO) {
            self->_videoRunning = YES;
            CMTimebaseSetTime(self->_videoTimebase, time);
            CMTimebaseSetRate(self->_videoTimebase, 1.0);
        }
        [self.delegate clock:self didChangeCurrentTime:time];
    });
}

- (BOOL)open
{
    return SGLockCondEXE00(self->_lock, ^BOOL {
        return self->_audioTimebase == NULL;
    }, ^{
        CMTimebaseCreateWithMasterClock(NULL, self->_masterClock, &self->_playbackTimebase);
        CMTimebaseSetRateAndAnchorTime(self->_playbackTimebase, 0.0, kCMTimeZero, CMClockGetTime(self->_masterClock));
        CMTimebaseCreateWithMasterTimebase(NULL, self->_playbackTimebase, &self->_audioTimebase);
        CMTimebaseCreateWithMasterTimebase(NULL, self->_playbackTimebase, &self->_videoTimebase);
        self->_audioRunning = NO;
        self->_videoRunning = NO;
        CMTime playbackTime = CMTimebaseGetTime(self->_playbackTimebase);
        CMTimebaseSetRateAndAnchorTime(self->_audioTimebase, 0.0, kCMTimeZero, playbackTime);
        CMTimebaseSetRateAndAnchorTime(self->_videoTimebase, 0.0, kCMTimeZero, playbackTime);
    });
}

- (BOOL)close
{
    return SGLockEXE00(self->_lock, ^{
        self->_audioRunning = NO;
        self->_videoRunning = NO;
        if (self->_audioTimebase) {
            CFRelease(self->_audioTimebase);
            self->_audioTimebase = NULL;
        }
        if (self->_videoTimebase) {
            CFRelease(self->_videoTimebase);
            self->_videoTimebase = NULL;
        }
        if (self->_playbackTimebase) {
            CFRelease(self->_playbackTimebase);
            self->_playbackTimebase = NULL;
        }
    });
}

- (BOOL)pause
{
    return SGLockEXE00(self->_lock, ^{
        CMTimebaseSetRate(self->_playbackTimebase, 0.0);
    });
}

- (BOOL)resume
{
    return SGLockEXE00(self->_lock, ^{
        CMTimebaseSetRate(self->_playbackTimebase, self->_rate);
    });
}

- (BOOL)flush
{
    return SGLockEXE00(self->_lock, ^{
        self->_audioRunning = NO;
        self->_videoRunning = NO;
        CMTime playbackTime = CMTimebaseGetTime(self->_playbackTimebase);
        CMTimebaseSetRateAndAnchorTime(self->_audioTimebase, 0.0, kCMTimeZero, playbackTime);
        CMTimebaseSetRateAndAnchorTime(self->_videoTimebase, 0.0, kCMTimeZero, playbackTime);
    });
}

@end
