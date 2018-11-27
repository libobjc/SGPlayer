//
//  SGGLView.h
//  SGPlayer
//
//  Created by Single on 2018/1/24.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPLFGLView.h"
#import "SGGLDefines.h"

@class SGGLView;

@protocol SGGLViewDelegate <NSObject>

- (BOOL)glView:(SGGLView *)glView display:(SGGLSize)size;
- (BOOL)glView:(SGGLView *)glView clear:(SGGLSize)size;
- (void)glViewDidFlush:(SGGLView *)glView;

@end

@interface SGGLView : SGPLFGLView

@property (nonatomic, weak) id<SGGLViewDelegate> delegate;
@property (nonatomic, readonly) SGGLSize displaySize;
@property (nonatomic, readonly) int64_t framesDisplayed;

- (BOOL)display;
- (BOOL)clear;

@end
