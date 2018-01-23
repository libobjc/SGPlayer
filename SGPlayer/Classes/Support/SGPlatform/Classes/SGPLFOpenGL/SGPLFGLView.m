//
//  SGPLFGLView.m
//  SGPlatform
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFGLView.h"
#import "SGPLFView.h"
#import "SGPLFScreen.h"


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

- (SGPLFImage *)snapshot
{
    return SGPLFViewGetCurrentSnapshot(self);
}

- (void)bindDrawable
{
    
}

- (void)prepare
{
    SGPLGLContextSetCurrentContext(self.context);
}

- (void)display
{
    if ([self.drawDelegate respondsToSelector:@selector(glkView:drawInRect:)]) {
        [self.drawDelegate glkView:self drawInRect:self.bounds];
    }
}

- (void)flush
{
    [self.openGLContext flushBuffer];
}

@end


#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV

@implementation SGPLFGLView

- (SGPLFImage *)snapshot
{
    return nil;
}

- (void)bindDrawable
{
    
}

- (void)prepare
{
    SGPLGLContextSetCurrentContext(self.context);
}

- (void)display
{
    if ([self.drawDelegate respondsToSelector:@selector(glkView:drawInRect:)]) {
        [self.drawDelegate glkView:self drawInRect:self.bounds];
    }
}

- (void)flush
{
    
}

@end

#endif
