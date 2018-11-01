//
//  SGClock.m
//  SGPlayer
//
//  Created by Single on 2018/6/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGClock.h"

@interface SGClock ()

@property (nonatomic, assign) CMTime keyTime;
@property (nonatomic, assign) CMTime keyDuration;
@property (nonatomic, assign) CMTime keyRate;
@property (nonatomic, assign) CMTime keyMediaTime;

@end

@implementation SGClock

- (instancetype)init
{
    if (self = [super init])
    {
        _startTime = kCMTimeInvalid;
        [self flush];
    }
    return self;
}

- (CMTime)time
{
    if (CMTIME_IS_INVALID(self.keyDuration) ||
        CMTimeCompare(self.keyDuration, kCMTimeZero) <= 0)
    {
        return self.keyTime;
    }
    CMTime mediaTime = SGCMTimeMakeWithSeconds(CACurrentMediaTime());
    CMTime interval = CMTimeSubtract(mediaTime, self.keyMediaTime);
    interval = SGCMTimeMultiply(interval, self.keyRate);
    interval = CMTimeMinimum(self.keyDuration, interval);
    CMTime position = CMTimeAdd(self.keyTime, interval);
    return position;
}

- (CMTime)unlimitedTime
{
    CMTime mediaTime = SGCMTimeMakeWithSeconds(CACurrentMediaTime());
    CMTime interval = CMTimeSubtract(mediaTime, self.keyMediaTime);
    interval = SGCMTimeMultiply(interval, self.keyRate);
    CMTime position = CMTimeAdd(self.keyTime, interval);
    return position;
}

- (BOOL)open
{
    return YES;
}

- (BOOL)close
{
    return YES;
}

- (void)updateKeyTime:(CMTime)time duration:(CMTime)duration rate:(CMTime)rate
{
    if (CMTIME_IS_INVALID(self.startTime))
    {
        _startTime = time;
        if ([self.delegate respondsToSelector:@selector(playbackClockDidChangeStartTime:)])
        {
            [self.delegate playbackClockDidChangeStartTime:self];
        }
    }
    self.keyTime = time;
    self.keyDuration = duration;
    self.keyRate = rate;
    self.keyMediaTime = SGCMTimeMakeWithSeconds(CACurrentMediaTime());
}

- (void)flush
{
    self.keyTime = kCMTimeZero;
    self.keyDuration = kCMTimeZero;
    self.keyRate = kCMTimeZero;
    self.keyMediaTime = kCMTimeZero;
}

@end
