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

@property (nonatomic, copy) void(^callback)(void);
@property (nonatomic, strong) SGPLFDisplayLink * displayLink;

@end

@implementation SGGLDisplayLink

+ (instancetype)displayLinkWithCallback:(void (^)(void))callback
{
    return [[SGGLDisplayLink alloc] initWithCallback:callback];
}

- (instancetype)initWithCallback:(void (^)(void))callback
{
    if (self = [super init])
    {
        self.callback = callback;
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
    self.callback();
}

- (void)invalidate
{
    [self.displayLink invalidate];
}

@end
