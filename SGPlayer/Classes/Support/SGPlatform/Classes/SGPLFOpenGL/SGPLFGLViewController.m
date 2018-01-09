//
//  SGPLFGLViewController.m
//  SGPlatform
//
//  Created by Single on 2017/3/29.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFGLViewController.h"

#if SGPLATFORM_TARGET_OS_MAC

#import "SGPLFDisplayLink.h"

@interface SGPLFGLViewController ()

@property (nonatomic, strong) SGPLFDisplayLink * displayLink;

@end

@implementation SGPLFGLViewController

- (void)loadView
{
    SGPLFGLView * glView = [[SGPLFGLView alloc] initWithFrame:CGRectZero];
    SGPLFGLViewSetDrawDelegate(glView, self);
    self.view = glView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.displayLink = [SGPLFDisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction)];
    self.displayLink.paused = NO;
}

- (void)displayLinkAction
{
    SGPLFGLView * glView = SGPLFGLViewControllerGetGLView(self);
    SGPLFGLViewDisplay(glView);
}

- (void)glkView:(SGPLFGLView *)view drawInRect:(CGRect)rect
{
    
}

- (BOOL)isPaused
{
    if (self.displayLink) {
        return self.displayLink.paused;
    }
    return YES;
}

- (void)setPaused:(BOOL)paused
{
    self.displayLink.paused = paused;
}

- (void)dealloc
{
    [self.displayLink invalidate];
    self.displayLink = nil;
}

@end


#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV





#endif


SGPLFGLView * SGPLFGLViewControllerGetGLView(SGPLFGLViewController * viewController)
{
    return (SGPLFGLView *)viewController.view;
}
