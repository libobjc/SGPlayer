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

#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV

@interface SGPLFGLView : UIView

#endif

@property (nonatomic, strong) SGPLFGLContext * context;
@property (nonatomic, strong) CAEAGLLayer * glLayer;
@property (nonatomic, assign) double glScale;

- (void)renderbufferStorage;
- (void)present;

@end
