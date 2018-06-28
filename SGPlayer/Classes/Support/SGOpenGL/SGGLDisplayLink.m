//
//  SGGLDisplayLink.m
//  SGPlayer
//
//  Created by Single on 2018/1/24.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLDisplayLink.h"
#import "SGPlatform.h"

@interface SGGLDisplayLink ()

@property (nonatomic, copy) void(^handler)(void);
@property (nonatomic, strong) SGPLFDisplayLink * displayLink;

@end

@implementation SGGLDisplayLink

+ (instancetype)displayLinkWithHandler:(void (^)(void))handler;
{
    return [[SGGLDisplayLink alloc] initWithHandler:handler];
}

- (instancetype)initWithHandler:(void (^)(void))handler
{
    if (self = [super init])
    {
        self.handler = handler;
        self.displayLink = [SGPLFDisplayLink displayLinkWithTarget:self selector:@selector(displayLinkHandler)];
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

- (NSTimeInterval)timestamp
{
    return self.displayLink.timestamp;
}

- (NSTimeInterval)duration
{
    return self.displayLink.duration;
}

- (NSTimeInterval)nextVSyncTimestamp
{
    return self.displayLink.timestamp + self.displayLink.duration;
}

- (void)invalidate
{
    [self.displayLink invalidate];
}

@end
