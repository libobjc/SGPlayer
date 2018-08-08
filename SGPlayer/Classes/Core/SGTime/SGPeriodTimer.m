//
//  SGPeriodTimer.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/8.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPeriodTimer.h"

@interface SGPeriodTimer ()

@property (nonatomic, copy) void (^handler)(void);
@property (nonatomic, strong) NSTimer * timer;

@end

@implementation SGPeriodTimer

- (instancetype)initWithHandler:(void (^)(void))handler
{
    if (self = [super init])
    {
        self.handler = handler;
    }
    return self;
}

- (void)start
{
    [self stop];
    self.timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timerHandler) userInfo:nil repeats:YES];
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
