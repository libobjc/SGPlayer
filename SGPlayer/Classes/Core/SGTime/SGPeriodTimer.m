//
//  SGPeriodTimer.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/8.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPeriodTimer.h"

@interface SGPeriodTimer ()

@property (nonatomic, strong) NSTimer * timer;
@property (nonatomic, copy) void (^handler)(void);

@end

@implementation SGPeriodTimer

- (instancetype)initWithHandler:(void (^)(void))handler
{
    if (self = [super init])
    {
        self.handler = handler;
        self.timeInterval = CMTimeMake(1, 1);
    }
    return self;
}

- (void)setTimeInterval:(CMTime)timeInterval
{
    if (CMTimeCompare(_timeInterval, timeInterval) != 0)
    {
        CMTime real = CMTimeMake(1, 1);
        if (CMTIME_IS_VALID(timeInterval) &&
            CMTimeCompare(timeInterval, kCMTimeZero) > 0)
        {
            real = timeInterval;
        }
        _timeInterval = real;
    }
}

- (void)start
{
    [self stop];
    self.timer = [NSTimer timerWithTimeInterval:CMTimeGetSeconds(self.timeInterval) target:self selector:@selector(timerHandler) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stop
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)timerHandler
{
    if (self.handler)
    {
        self.handler();
    }
}

@end
