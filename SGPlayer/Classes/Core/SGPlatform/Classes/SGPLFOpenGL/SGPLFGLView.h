//
//  SGPLFGLView.h
//  SGPlatform
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFOpenGL.h"
#import "SGPLFGLContext.h"

#if SGPLATFORM_TARGET_OS_MAC

@interface SGPLFGLView : NSOpenGLView

- (void)layoutSubviews;

#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV

@interface SGPLFGLView : UIView

@property (nonatomic, strong) CAEAGLLayer * glLayer;

- (void)renderbufferStorage;

#endif

@property (nonatomic, strong) SGPLFGLContext * context;
@property (nonatomic, assign) double glScale;

- (void)prepare;
- (void)present;

@end
