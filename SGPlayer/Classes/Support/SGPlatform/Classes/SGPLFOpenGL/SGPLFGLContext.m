//
//  SGPLFGLContext.m
//  SGPlatform
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFGLContext.h"

#if SGPLATFORM_TARGET_OS_MAC


NSOpenGLPixelFormat * SGPLFGLContextGetPixelFormat(SGPLFGLContext * context)
{
    return context.pixelFormat;
}

SGPLFGLContext * SGPLFGLContextAllocInit(void)
{
    NSOpenGLPixelFormatAttribute pixelFormatAttributes[] = {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated, 0,
        0
    };
    
    NSOpenGLPixelFormat * pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:pixelFormatAttributes];
    return [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
}

void SGPLGLContextSetCurrentContext(SGPLFGLContext * context)
{
    if (context) {
        [context makeCurrentContext];
    } else {
        [NSOpenGLContext clearCurrentContext];
    }
}


#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV


SGPLFGLContext * SGPLFGLContextAllocInit(void)
{
    return [[SGPLFGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
}

void SGPLGLContextSetCurrentContext(SGPLFGLContext * context)
{
    [EAGLContext setCurrentContext:context];
}


#endif
