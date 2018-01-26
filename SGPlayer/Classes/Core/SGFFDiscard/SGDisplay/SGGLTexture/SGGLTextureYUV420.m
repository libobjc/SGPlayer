//
//  SGGLTextureYUV420.m
//  SGPlayer
//
//  Created by Single on 2017/3/27.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGGLTextureYUV420.h"

static int gl_texture[3] =
{
    GL_TEXTURE0,
    GL_TEXTURE1,
    GL_TEXTURE2,
};

@implementation SGGLTextureYUV420

{
    GLuint _gl_texture_ids[3];
}

- (instancetype)init
{
    if (self = [super init])
    {
        glGenTextures(3, _gl_texture_ids);
    }
    return self;
}

- (void)dealloc
{
    if (_gl_texture_ids[0])
    {
        glDeleteTextures(3, _gl_texture_ids);
        _gl_texture_ids[0] = 0;
        _gl_texture_ids[1] = 0;
        _gl_texture_ids[1] = 0;
    }
}

- (void)upload:(uint8_t **)data size:(SGGLSize)size
{
    static int count = 3;
    int widths[3]  = {size.width, size.width / 2, size.width / 2};
    int heights[3] = {size.height, size.height / 2, size.height / 2};
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    for (int i = 0; i < count; i++)
    {
        glActiveTexture(gl_texture[i]);
        glBindTexture(GL_TEXTURE_2D, _gl_texture_ids[i]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, widths[i], heights[i], 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, data[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
}

- (BOOL)updateTextureWithGLFrame:(SGGLFrame *)glFrame aspect:(CGFloat *)aspect
{
    return YES;
}

@end
