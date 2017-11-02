//
//  SGGLTextureYUV420.m
//  SGPlayer
//
//  Created by Single on 2017/3/27.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGGLTextureYUV420.h"
#import "SGPlayerBuildConfig.h"

@interface SGGLTextureYUV420 ()


@end

@implementation SGGLTextureYUV420

static GLuint gl_texture_ids[3];

- (instancetype)init
{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            glGenTextures(3, gl_texture_ids);
        });
    }
    return self;
}

- (BOOL)updateTextureWithGLFrame:(SGGLFrame *)glFrame aspect:(CGFloat *)aspect
{
#if SGPlayerBuildConfig_FFmpeg_Enable
    SGFFAVYUVVideoFrame * videoFrame = [glFrame pixelBufferForYUV420];
    
    if (!videoFrame) {
        return NO;
    }
    
    const int frameWidth = videoFrame.width;
    const int frameHeight = videoFrame.height;
    * aspect = (frameWidth * 1.0) / (frameHeight * 1.0);
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    const int widths[3]  = {
        frameWidth,
        frameWidth / 2,
        frameWidth / 2
    };
    const int heights[3] = {
        frameHeight,
        frameHeight / 2,
        frameHeight / 2
    };
    
    for (SGYUVChannel channel = SGYUVChannelLuma; channel < SGYUVChannelCount; channel++)
    {
        glActiveTexture(GL_TEXTURE0 + channel);
        glBindTexture(GL_TEXTURE_2D, gl_texture_ids[channel]);
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_LUMINANCE,
                     widths[channel],
                     heights[channel],
                     0,
                     GL_LUMINANCE,
                     GL_UNSIGNED_BYTE,
                     videoFrame->channel_pixels[channel]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    
    return YES;
#else
    return NO;
#endif
}

@end
