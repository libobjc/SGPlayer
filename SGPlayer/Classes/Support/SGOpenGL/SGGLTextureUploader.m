//
//  SGGLTextureUploader.m
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLTextureUploader.h"
#import "SGPLFOpenGL.h"

static int gl_texture[3] =
{
    GL_TEXTURE0,
    GL_TEXTURE1,
    GL_TEXTURE2,
};

@implementation SGGLTextureUploader

{
    GLuint _gl_texture_ids[3];
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

- (void)setupGLTextureIfNeed
{
    if (!_gl_texture_ids[0])
    {
        glGenTextures(3, _gl_texture_ids);
    }
}

- (BOOL)uploadWithType:(SGGLTextureType)type data:(uint8_t **)data size:(SGGLSize)size
{
    [self setupGLTextureIfNeed];
    switch (type)
    {
        case SGGLTextureTypeUnknown:
            return NO;
        case SGGLTextureTypeYUV420P:
        {
            static int count = 3;
            int widths[3]  = {size.width, size.width / 2, size.width / 2};
            int heights[3] = {size.height, size.height / 2, size.height / 2};
            int formats[3] = {GL_LUMINANCE, GL_LUMINANCE, GL_LUMINANCE};
            [self uploadWithData:data widths:widths heights:heights formats:formats count:count];
        }
            return YES;
        case SGGLTextureTypeNV12:
        {
            static int count = 2;
            int widths[2]  = {size.width, size.width / 2};
            int heights[2] = {size.height, size.height / 2};
            int formats[2] = {GL_LUMINANCE, GL_LUMINANCE_ALPHA};
            [self uploadWithData:data widths:widths heights:heights formats:formats count:count];
        }
            return NO;
    }
    return NO;
}

- (void)uploadWithData:(uint8_t **)data widths:(int *)widths heights:(int *)heights formats:(int *)formats count:(int)count
{
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    for (int i = 0; i < count; i++)
    {
        glActiveTexture(gl_texture[i]);
        glBindTexture(GL_TEXTURE_2D, _gl_texture_ids[i]);
        glTexImage2D(GL_TEXTURE_2D, 0, formats[i], widths[i], heights[i], 0, formats[i], GL_UNSIGNED_BYTE, data[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
}

- (BOOL)uploadWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    return NO;
}

@end
