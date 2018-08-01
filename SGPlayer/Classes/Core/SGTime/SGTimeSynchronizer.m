//
//  SGTimeSynchronizer.m
//  SGPlayer
//
//  Created by Single on 2018/6/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGTimeSynchronizer.h"

@interface SGTimeSynchronizer ()

@property (nonatomic, assign) CMTime keyPosition;
@property (nonatomic, assign) CMTime keyDuration;
@property (nonatomic, assign) CMTime keyRate;
@property (nonatomic, assign) CMTime keyMediaTime;

@end

@implementation SGTimeSynchronizer

- (instancetype)init
{
    if (self = [super init])
    {
        [self flush];
    }
    return self;
}

- (CMTime)position
{
    if (CMTIME_IS_INVALID(self.keyDuration))
    {
        return self.keyPosition;
    }
    if (CMTimeCompare(self.keyDuration, kCMTimeZero) <= 0)
    {
        return self.keyPosition;
    }
    CMTime mediaTime = SGTimeMakeWithSeconds(CACurrentMediaTime());
    CMTime interval = CMTimeSubtract(mediaTime, self.keyMediaTime);
    interval = CMTimeMake(interval.value * self.keyRate.value, interval.timescale * self.keyRate.timescale);
    interval = CMTimeMinimum(self.keyDuration, interval);
    CMTime position = CMTimeAdd(self.keyPosition, interval);
    return position;
}

- (void)updatePosition:(CMTime)position duration:(CMTime)duration rate:(CMTime)rate
{
    self.keyPosition = position;
    self.keyDuration = duration;
    self.keyRate = rate;
    self.keyMediaTime = SGTimeMakeWithSeconds(CACurrentMediaTime());
}

- (void)flush
{
    self.keyPosition = kCMTimeZero;
    self.keyDuration = kCMTimeZero;
    self.keyMediaTime = kCMTimeZero;
}

@end
