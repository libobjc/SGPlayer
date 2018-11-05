//
//  SGGLTimer.m
//  SGPlayer
//
//  Created by Single on 2018/6/27.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGGLTimer.h"

@interface SGGLTimer ()

@property (nonatomic, copy) void (^handler)(void);
@property (nonatomic, strong) NSTimer * timer;

@end

@implementation SGGLTimer

- (instancetype)initWithTimeInterval:(double)timeInterval handler:(void (^)(void))handler
{
    if (self = [super init]) {
        self.handler = handler;
        self.timer = [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(timerHandler) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)dealloc
{
    [self invalidate];
}

- (void)timerHandler
{
    if (self.handler) {
        self.handler();
    }
}

- (void)setPaused:(BOOL)paused
{
    if (_paused != paused) {
        _paused = paused;
        self.timer.fireDate = _paused ? [NSDate distantFuture] : [NSDate distantPast];
    }
}

- (void)invalidate
{
    [self.timer invalidate];
}

@end
