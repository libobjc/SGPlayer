//
//  SGPlaybackTimeSync.m
//  SGPlayer
//
//  Created by Single on 2018/6/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPlaybackTimeSync.h"

@interface SGPlaybackTimeSync ()

@property (nonatomic, assign) CMTime keyTime;
@property (nonatomic, assign) CMTime keyDuration;
@property (nonatomic, assign) CMTime keyRate;
@property (nonatomic, assign) CMTime keyMediaTime;

@end

@implementation SGPlaybackTimeSync

- (instancetype)init
{
    if (self = [super init])
    {
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
    interval = CMTimeMake(interval.value * self.keyRate.value, interval.timescale * self.keyRate.timescale);
    interval = CMTimeMinimum(self.keyDuration, interval);
    CMTime position = CMTimeAdd(self.keyTime, interval);
    return position;
}

- (CMTime)unlimitedTime
{
    CMTime mediaTime = SGCMTimeMakeWithSeconds(CACurrentMediaTime());
    CMTime interval = CMTimeSubtract(mediaTime, self.keyMediaTime);
    interval = CMTimeMake(interval.value * self.keyRate.value, interval.timescale * self.keyRate.timescale);
    CMTime position = CMTimeAdd(self.keyTime, interval);
    return position;
}

- (void)updateKeyTime:(CMTime)time duration:(CMTime)duration rate:(CMTime)rate
{
    self.keyTime = time;
    self.keyDuration = duration;
    self.keyRate = rate;
    self.keyMediaTime = SGCMTimeMakeWithSeconds(CACurrentMediaTime());
}

- (void)refresh
{
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
