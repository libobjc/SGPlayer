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

- (void)glView:(SGGLView *)glView draw:(SGGLSize)size;

@end

@interface SGGLView : SGPLFGLView

@property (nonatomic, weak) id <SGGLViewDelegate> delegate;

- (void)display;
- (void)clear;

@end
