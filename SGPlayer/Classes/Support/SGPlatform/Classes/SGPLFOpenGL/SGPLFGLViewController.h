//
//  SGPLFGLViewController.h
//  SGPlatform
//
//  Created by Single on 2017/3/29.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFOpenGL.h"

#import "SGPLFGLView.h"

#if SGPLATFORM_TARGET_OS_MAC


@interface SGPLFGLViewController : NSViewController <SGPLFGLViewDelegate>

@property (nonatomic, getter=isPaused) BOOL paused;

@property (nonatomic, assign) NSInteger preferredFramesPerSecond;

@end


#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV


typedef GLKViewController SGPLFGLViewController;


#endif

SGPLFGLView * SGPLFGLViewControllerGetGLView(SGPLFGLViewController * viewController);
