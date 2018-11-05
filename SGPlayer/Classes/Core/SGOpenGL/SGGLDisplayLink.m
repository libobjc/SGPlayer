//
//  SGGLDisplayLink.m
//  SGPlayer
//
//  Created by Single on 2018/1/24.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLDisplayLink.h"
#import "SGPLFDisplayLink.h"

@interface SGGLDisplayLink ()

@property (nonatomic, copy) void (^handler)(void);
@property (nonatomic, strong) SGPLFDisplayLink * displayLink;

@end

@implementation SGGLDisplayLink

- (instancetype)initWithTimeInterval:(double)timeInterval handler:(void (^)(void))handler
{
    if (self = [super init]) {
        self.handler = handler;
        self.displayLink = [SGPLFDisplayLink displayLinkWithTarget:self selector:@selector(displayLinkHandler)];
        if (@available(iOS 10.0, *)) {
            self.displayLink.preferredFramesPerSecond = 1.0f / timeInterval;
        } else {
            self.displayLink.frameInterval = 60 * timeInterval;
        }
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)dealloc
{
    [self invalidate];
}

- (void)displayLinkHandler
{
    if (self.handler)
    {
        self.handler();
    }
}

- (void)setPaused:(BOOL)paused
{
    self.displayLink.paused = paused;
}

- (BOOL)paused
{
    return self.displayLink.isPaused;
}

- (double)timestamp
{
    return self.displayLink.timestamp;
}

- (double)duration
{
    return self.displayLink.duration;
}

- (double)nextTimestamp
{
    return self.displayLink.timestamp + self.displayLink.duration;
}

- (void)invalidate
{
    [self.displayLink invalidate];
}

@end
