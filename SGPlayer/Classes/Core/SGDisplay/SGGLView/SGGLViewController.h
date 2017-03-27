//
//  SGGLViewController.h
//  SGPlayer
//
//  Created by Single on 2017/3/27.
//  Copyright © 2017年 single. All rights reserved.
//

#import <SGPlatform/SGPlatform.h>
#import "SGDisplayView.h"

@interface SGGLViewController : SGPLFGLViewController

+ (instancetype)viewControllerWithDisplayView:(SGDisplayView *)displayView;

@property (nonatomic, weak, readonly) SGDisplayView * displayView;

- (void)reloadViewport;
- (void)flushClearColor;
- (SGPLFImage *)snapshot;

@end
