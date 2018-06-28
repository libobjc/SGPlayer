//
//  SGFFTimeSynchronizer.m
//  SGPlayer
//
//  Created by Single on 2018/6/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFFTimeSynchronizer.h"

@interface SGFFTimeSynchronizer ()

@property (nonatomic, assign) CMTime keyPosition;
@property (nonatomic, assign) CMTime keyDuration;
@property (nonatomic, assign) CMTime keyMediaTime;

@end

@implementation SGFFTimeSynchronizer

- (instancetype)init
{
    if (self = [super init])
    {
        [self flush];
    }
    return self;
}

- (CMTime)realPositionWithRate:(CMTime)rate
{
    if (CMTIME_IS_INVALID(self.keyDuration))
    {
        return self.keyPosition;
    }
    if (CMTimeCompare(self.keyDuration, kCMTimeZero) <= 0)
    {
        return self.keyPosition;
    }
    CMTime mediaTime = SGFFTimeMakeWithSeconds(CACurrentMediaTime());
    CMTime interval = CMTimeSubtract(mediaTime, self.keyMediaTime);
    interval = CMTimeMake(interval.value * rate.value, interval.timescale * rate.timescale);
    interval = CMTimeMinimum(self.keyDuration, interval);
    CMTime position = CMTimeAdd(self.keyPosition, interval);
    return position;
}

- (void)updateKeyPosition:(CMTime)keyPosition keyDuration:(CMTime)keyDuration
{
    self.keyPosition = keyPosition;
    self.keyDuration = keyDuration;
    self.keyMediaTime = SGFFTimeMakeWithSeconds(CACurrentMediaTime());
}

- (void)flush
{
    self.keyPosition = kCMTimeZero;
    self.keyDuration = kCMTimeZero;
    self.keyMediaTime = kCMTimeZero;
}

@end
