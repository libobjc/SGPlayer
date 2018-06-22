//
//  SGPLFGLView.m
//  SGPlatform
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFGLView.h"


#if SGPLATFORM_TARGET_OS_MAC


@implementation SGPLFGLView

- (void)setContext:(SGPLFGLContext *)context
{
    self.openGLContext = context;
}

- (SGPLFGLContext *)context
{
    return self.openGLContext;
}

- (void)present
{
    [self.openGLContext flushBuffer];
}

@end


#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV


@implementation SGPLFGLView

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.glScale = 1.0f;
        if ([self respondsToSelector:@selector(setContentScaleFactor:)])
        {
            self.contentScaleFactor = [[UIScreen mainScreen] scale];
            self.glScale = self.contentScaleFactor;
        }
        
        self.glLayer = (CAEAGLLayer *)self.layer;
        self.glLayer.opaque = YES;
        self.glLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking : @(NO), kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8};
    }
    return self;
}

- (void)renderbufferStorage
{
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.glLayer];
}

- (void)present
{
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

@end


#endif
