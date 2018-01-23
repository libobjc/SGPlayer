//
//  SGGLTexture.h
//  SGPlayer
//
//  Created by Single on 2017/3/27.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "SGGLFrame.h"

@interface SGGLTexture : NSObject

- (BOOL)updateTextureWithGLFrame:(SGGLFrame *)glFrame aspect:(CGFloat *)aspect;
- (void)flush;

@end
