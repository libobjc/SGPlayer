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


@interface SGPLFGLView : NSOpenGLView

@end

@protocol SGPLFGLViewDelegate <NSObject>
- (void)glkView:(SGPLFGLView *)view drawInRect:(CGRect)rect;
@end


#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV


typedef GLKView SGPLFGLView;

@protocol SGPLFGLViewDelegate <GLKViewDelegate>
- (void)glkView:(SGPLFGLView *)view drawInRect:(CGRect)rect;
@end


#endif

void SGPLFGLViewDisplay(SGPLFGLView * view);
void SGPLFGLViewSetDrawDelegate(SGPLFGLView * view, id <SGPLFGLViewDelegate> drawDelegate);
void SGPLFGLViewSetContext(SGPLFGLView * view, SGPLFGLContext * context);
SGPLFGLContext * SGPLFGLViewGetContext(SGPLFGLView * view);
void SGPLFGLViewPrepareOpenGL(SGPLFGLView * view);
void SGPLFGLViewFlushBuffer(SGPLFGLView * view);
void SGPLFGLViewBindFrameBuffer(SGPLFGLView * view);
SGPLFImage * SGPLFGLViewGetCurrentSnapshot(SGPLFGLView * view);
