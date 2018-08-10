//
//  SGPLFGLView.h
//  SGPlatform
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFOpenGL.h"

#import "SGPLFGLContext.h"
#import "SGPLFImage.h"

#if SGPLATFORM_TARGET_OS_MAC


@interface SGPLFGLView2 : NSOpenGLView

@end

@protocol SGPLFGLView2Delegate <NSObject>
- (void)glkView:(SGPLFGLView *)view drawInRect:(CGRect)rect;
@end


#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV


typedef GLKView SGPLFGLView2;

@protocol SGPLFGLView2Delegate <GLKViewDelegate>
- (void)glkView:(SGPLFGLView2 *)view drawInRect:(CGRect)rect;
@end


#endif

void SGPLFGLViewDisplay(SGPLFGLView2 * view);
void SGPLFGLViewSetDrawDelegate(SGPLFGLView2 * view, id <SGPLFGLView2Delegate> drawDelegate);
void SGPLFGLViewSetContext(SGPLFGLView2 * view, SGPLFGLContext * context);
SGPLFGLContext * SGPLFGLViewGetContext(SGPLFGLView2 * view);
void SGPLFGLViewPrepareOpenGL(SGPLFGLView2 * view);
void SGPLFGLViewFlushBuffer(SGPLFGLView2 * view);
void SGPLFGLViewBindFrameBuffer(SGPLFGLView2 * view);
SGPLFImage * SGPLFGLViewGetCurrentSnapshot(SGPLFGLView2 * view);
