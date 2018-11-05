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
        _displayLink = nil;
        self.target = target;
        self.selector = selector;
        CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
        CVDisplayLinkSetOutputCallback(_displayLink,
                                       displayLinkCallback,
                                       (__bridge void *)(self));
    }
    return self;
}

- (void)setPaused:(BOOL)paused
{
    if (_displayLink) {
        if (paused) {
            CVDisplayLinkStop(_displayLink);
        } else {
            CVDisplayLinkStart(_displayLink);
        }
    }
}

- (BOOL)paused
{
    if (_displayLink) {
        return !CVDisplayLinkIsRunning(_displayLink);
    }
    return YES;
}

- (NSTimeInterval)timestamp
{
    if (_displayLink) {
        CVTimeStamp t = {};
        if (CVDisplayLinkGetCurrentTime(_displayLink, &t) == kCVReturnSuccess && t.flags & kCVTimeStampHostTimeValid) {
            return t.hostTime / NSEC_PER_SEC;
        };
    }
    return 0;
}

- (NSTimeInterval)duration
{
    if (_displayLink) {
        return CVDisplayLinkGetActualOutputVideoRefreshPeriod(_displayLink);
    }
    return 0;
}

- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode
{
    
}

- (void)invalidate
{
    if (_displayLink) {
        CVDisplayLinkStop(_displayLink);
        CVDisplayLinkRelease(_displayLink);
        _displayLink = nil;
    }
}

- (void)dealloc
{
    [self invalidate];
}

static CVReturn displayLinkCallback(CVDisplayLinkRef displayLinkRef,
                                    const CVTimeStamp * now,
                                    const CVTimeStamp * outputTime,
                                    CVOptionFlags flagsIn,
                                    CVOptionFlags * flagsOut,
                                    void * displayLinkContext)
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


