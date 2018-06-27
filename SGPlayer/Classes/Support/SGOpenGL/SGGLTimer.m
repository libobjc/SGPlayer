//
//  SGGLTimer.m
//  SGPlayer
//
//  Created by Single on 2018/6/27.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGGLTimer.h"

@interface SGGLTimer ()

@property (nonatomic, copy) void(^handler)(void);
@property (nonatomic, strong) NSTimer * timer;

@end

@implementation SGGLTimer

+ (instancetype)timerWithTimeInterval:(NSTimeInterval)timeInterval handler:(void (^)(void))handler
{
    return [[self alloc] initWithTimeInterval:timeInterval handler:handler];
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval handler:(void (^)(void))handler
{
    if (self = [super init])
    {
        self.handler = handler;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(timerHandler) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)dealloc
{
    [self invalidate];
}

- (void)timerHandler
{
    if (self.handler)
    {
        self.handler();
    }
}

- (void)setFireDate:(NSDate *)fireDate
{
    self.timer.fireDate = fireDate;
}

- (NSDate *)fireDate
{
    return self.timer.fireDate;
}

- (NSTimeInterval)timeInterval
{
    return self.timer.timeInterval;
}

- (BOOL)valid
{
    return self.timer.isValid;
}

- (void)invalidate
{
    [self.timer invalidate];
}

@end
