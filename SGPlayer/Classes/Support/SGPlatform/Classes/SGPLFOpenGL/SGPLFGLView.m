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


void SGPLFGLViewPrepareOpenGL(SGPLFGLView * view)
{
    SGPLFGLContext * context = SGPLFGLViewGetContext(view);
    SGPLGLContextSetCurrentContext(context);
}


#if SGPLATFORM_TARGET_OS_MAC


@interface SGPLFGLView ()

@property (nonatomic, weak) id <SGPLFGLViewDelegate> drawDelegate;

@end

@implementation SGPLFGLView

void SGPLFGLViewDisplay(SGPLFGLView * view)
{
    if ([view.drawDelegate respondsToSelector:@selector(glkView:drawInRect:)]) {
        [view.drawDelegate glkView:view drawInRect:view.bounds];
    }
}

void SGPLFGLViewSetDrawDelegate(SGPLFGLView * view, id <SGPLFGLViewDelegate> drawDelegate)
{
    view.drawDelegate = drawDelegate;
}

void SGPLFGLViewSetContext(SGPLFGLView * view, SGPLFGLContext * context)
{
    view.openGLContext = context;
}

SGPLFGLContext * SGPLFGLViewGetContext(SGPLFGLView * view)
{
    return view.openGLContext;
}

void SGPLFGLViewBindFrameBuffer(SGPLFGLView * view)
{
    
}

SGPLFImage * SGPLFGLViewGetCurrentSnapshot(SGPLFGLView * view)
{
    return SGPLFViewGetCurrentSnapshot(view);
}

void SGPLFGLViewFlushBuffer(SGPLFGLView * view)
{
    [view.openGLContext flushBuffer];
}

@end


#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV


void SGPLFGLViewDisplay(SGPLFGLView * view)
{
    [view display];
}

void SGPLFGLViewSetDrawDelegate(SGPLFGLView * view, id <SGPLFGLViewDelegate> drawDelegate)
{
    view.delegate = drawDelegate;
}

void SGPLFGLViewSetContext(SGPLFGLView * view, SGPLFGLContext * context)
{
    view.context = context;
}

SGPLFGLContext * SGPLFGLViewGetContext(SGPLFGLView * view)
{
    return view.context;
}

void SGPLFGLViewBindFrameBuffer(SGPLFGLView * view)
{
    [view bindDrawable];
}

SGPLFImage * SGPLFGLViewGetCurrentSnapshot(SGPLFGLView * view)
{
    return view.snapshot;
}

void SGPLFGLViewFlushBuffer(SGPLFGLView * view)
{
    
}


#endif

