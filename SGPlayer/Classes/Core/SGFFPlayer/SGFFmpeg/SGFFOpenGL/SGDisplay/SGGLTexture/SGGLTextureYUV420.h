//
//  SGGLTextureYUV420.h
//  SGPlayer
//
//  Created by Single on 2017/3/27.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGGLTexture.h"
#import "SGFFVideoOutputRender.h"
#import "SGGLDefines.h"

@interface SGGLTextureYUV420 : SGGLTexture

- (void)upload:(uint8_t **)data size:(SGGLSize)size;

@end
