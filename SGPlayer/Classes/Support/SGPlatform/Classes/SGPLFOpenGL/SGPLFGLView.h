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


@class SGPLFGLView;

@protocol SGPLFGLViewDelegate <NSObject>

- (void)glkView:(SGPLFGLView *)view drawInRect:(CGRect)rect;

@end


#if SGPLATFORM_TARGET_OS_MAC
@interface SGPLFGLView : NSOpenGLView
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
@interface SGPLFGLView : UIView
#endif

@property (nonatomic, weak) id <SGPLFGLViewDelegate> drawDelegate;
@property (nonatomic, strong) SGPLFGLContext * context;

- (SGPLFImage *)snapshot;

- (void)bindDrawable;
- (void)prepare;
- (void)display;
- (void)flush;

@end
