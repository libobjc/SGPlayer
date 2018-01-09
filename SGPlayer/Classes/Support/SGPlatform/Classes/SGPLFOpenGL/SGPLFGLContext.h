//
//  SGPLFGLContext.h
//  SGPlatform
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFOpenGL.h"

#if SGPLATFORM_TARGET_OS_MAC


typedef NSOpenGLContext SGPLFGLContext;

NSOpenGLPixelFormat * SGPLFGLContextGetPixelFormat(SGPLFGLContext * context);


#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV


typedef EAGLContext SGPLFGLContext;


#endif

SGPLFGLContext * SGPLFGLContextAllocInit(void);
void SGPLGLContextSetCurrentContext(SGPLFGLContext * context);
