//
//  SGPLFDisplayLink.m
//  SGPlatform
//
//  Created by Single on 2017/2/24.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFDisplayLink.h"
#import <QuartzCore/QuartzCore.h>

#if SGPLATFORM_TARGET_OS_MAC


@interface SGPLFDisplayLink ()

{
    CVDisplayLinkRef _displayLink;
}

@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL selector;

@end

@implementation SGPLFDisplayLink

+ (SGPLFDisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)selector
{
    return [[self alloc] initWithTarget:target selector:selector];
}

- (instancetype)initWithTarget:(id)target selector:(SEL)selector
{
    if (self = [super init]) {
        self->_displayLink = NULL;
        self.target = target;
        self.selector = selector;
        CVDisplayLinkCreateWithActiveCGDisplays(&self->_displayLink);
        CVDisplayLinkSetOutputCallback(self->_displayLink,
                                       QCDisplayLinkCallback,
                                       (__bridge void *)(self));
    }
    return self;
}

- (void)setPaused:(BOOL)paused
{
    if (self->_displayLink) {
        if (paused) {
            CVDisplayLinkStop(self->_displayLink);
        } else {
            CVDisplayLinkStart(self->_displayLink);
        }
    }
}

- (BOOL)paused
{
    if (self->_displayLink) {
        return CVDisplayLinkIsRunning(self->_displayLink);
    }
    return YES;
}

- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode
{
    
}

- (void)invalidate
{
    self.paused = YES;
    if (self->_displayLink) {
        CVDisplayLinkRelease(self->_displayLink);
        self->_displayLink = NULL;
    }
}

- (void)dealloc
{
    [self invalidate];
}

static CVReturn QCDisplayLinkCallback(CVDisplayLinkRef displayLinkRef,
                                           const CVTimeStamp *now,
                                           const CVTimeStamp *outputTime,
                                           CVOptionFlags flagsIn,
                                           CVOptionFlags *flagsOut,
                                           void   *displayLinkContext)
{
    SGPLFDisplayLink * displayLink = (__bridge SGPLFDisplayLink *)displayLinkContext;
    if ([displayLink.target respondsToSelector:displayLink.selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [displayLink.target performSelectorOnMainThread:displayLink.selector withObject:nil waitUntilDone:NO];
#pragma clang diagnostic pop
    }
    return kCVReturnSuccess;
}

@end


#endif


