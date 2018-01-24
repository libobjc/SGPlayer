//
//  SGGLView.h
//  SGPlayer
//
//  Created by Single on 2018/1/24.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPLFGLView.h"

typedef struct SGGLSize {
    int width;
    int height;
} SGGLSize;

@interface SGGLView : SGPLFGLView

@property (nonatomic, assign, readonly) SGGLSize displaySize;

- (void)display:(void(^)(void))prepare;
- (void)clear;

@end
