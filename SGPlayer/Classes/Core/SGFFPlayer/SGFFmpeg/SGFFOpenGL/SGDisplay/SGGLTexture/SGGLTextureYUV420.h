//
//  SGGLTextureYUV420.h
//  SGPlayer
//
//  Created by Single on 2017/3/27.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGGLTexture.h"
#import "SGFFVideoOutputRender.h"

@interface SGGLTextureYUV420 : SGGLTexture

- (BOOL)updateTexture:(SGFFVideoOutputRender *)render;

@end
