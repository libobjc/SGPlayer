//
//  SGGLTextureUploader.m
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLTextureUploader.h"
#import "SGPLFOpenGL.h"

static int gl_texture[3] = {
    GL_TEXTURE0,
    GL_TEXTURE1,
    GL_TEXTURE2,
};

@interface SGGLTextureUploader ()

{
    GLuint _gl_texture_ids[3];
    CVOpenGLESTextureCacheRef _openGLESTextureCache;
}

@property (nonatomic, strong) SGPLFGLContext * context;
@property (nonatomic, assign) BOOL setupOpenGLESTextureCacheFailed;

@end

@implementation SGGLTextureUploader

- (instancetype)initWithGLContext:(SGPLFGLContext *)context
{
    if (self = [super init]) {
        self.context = context;
    }
    return self;
}

- (void)dealloc
{
    if (_gl_texture_ids[0]) {
        glDeleteTextures(3, _gl_texture_ids);
        _gl_texture_ids[0] = 0;
        _gl_texture_ids[1] = 0;
        _gl_texture_ids[1] = 0;
    }
    if (_openGLESTextureCache) {
        CVOpenGLESTextureCacheFlush(_openGLESTextureCache, 0);
        CFRelease(_openGLESTextureCache);
        _openGLESTextureCache = NULL;
    }
}

- (void)setupGLTextureIfNeeded
{
    if (!_gl_texture_ids[0])
    {
        glGenTextures(3, _gl_texture_ids);
    }
}

- (void)setupOpenGLESTextureCacheIfNeeded
{
    if (!_openGLESTextureCache && !self.setupOpenGLESTextureCacheFailed) {
        CVReturn result = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_openGLESTextureCache);
        if (result != noErr) {
            self.setupOpenGLESTextureCacheFailed = YES;
        }
    }
}

- (BOOL)uploadWithType:(SGGLTextureType)type
                  data:(uint8_t **)data
                  size:(SGGLSize)size
{
    [self setupGLTextureIfNeeded];
    if (type == SGGLTextureTypeYUV420P) {
        static int count = 3;
        int widths[3]  = {size.width, size.width / 2, size.width / 2};
        int heights[3] = {size.height, size.height / 2, size.height / 2};
        int formats[3] = {GL_LUMINANCE, GL_LUMINANCE, GL_LUMINANCE};
        return [self uploadWithData:data
                             widths:widths
                            heights:heights
                    internalFormats:formats
                            formats:formats
                              count:count];
    } else if (type == SGGLTextureTypeNV12) {
        static int count = 2;
        int widths[2]  = {size.width, size.width / 2};
        int heights[2] = {size.height, size.height / 2};
        int formats[2] = {GL_LUMINANCE, GL_LUMINANCE_ALPHA};
        return [self uploadWithData:data
                             widths:widths
                            heights:heights
                    internalFormats:formats
                            formats:formats
                              count:count];
    }
    return NO;
}

- (BOOL)uploadWithData:(uint8_t **)data
                widths:(int *)widths
               heights:(int *)heights
       internalFormats:(int *)internalFormats
               formats:(int *)formats
                 count:(int)count
{
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    for (int i = 0; i < count; i++) {
        glActiveTexture(gl_texture[i]);
        glBindTexture(GL_TEXTURE_2D, _gl_texture_ids[i]);
        glTexImage2D(GL_TEXTURE_2D, 0, internalFormats[i], widths[i], heights[i], 0, formats[i], GL_UNSIGNED_BYTE, data[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    return YES;
}

- (BOOL)uploadWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    [self setupOpenGLESTextureCacheIfNeeded];
    if (!_openGLESTextureCache) {
        return NO;
    }
    CVOpenGLESTextureCacheFlush(_openGLESTextureCache, 0);
    GLsizei width = (int)CVPixelBufferGetWidth(pixelBuffer);
    GLsizei height = (int)CVPixelBufferGetHeight(pixelBuffer);
    OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);
    if (format == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
        static int count = 2;
        int widths[2]  = {width, width / 2};
        int heights[2] = {height, height / 2};
        int formats[2] = {GL_RED_EXT, GL_RG_EXT};
        return [self uploadWithCVPixelBuffer:pixelBuffer
                                      widths:widths
                                     heights:heights
                             internalFormats:formats
                                     formats:formats
                                       count:count];
    } else if (format == kCVPixelFormatType_32BGRA) {
        static int count = 1;
        int widths[1]  = {width};
        int heights[1] = {height};
        int internalFormats[1] = {GL_RGBA};
        int formats[1] = {GL_BGRA};
        return [self uploadWithCVPixelBuffer:pixelBuffer
                                      widths:widths
                                     heights:heights
                             internalFormats:internalFormats
                                     formats:formats
                                       count:count];
    }
    return NO;
}

- (BOOL)uploadWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
                         widths:(int *)widths
                        heights:(int *)heights
                internalFormats:(int *)internalFormats
                        formats:(int *)formats
                          count:(int)count
{
    CVPixelBufferRetain(pixelBuffer);
    BOOL success = YES;
    for (int i = 0; i < count; i++) {
        CVReturn result;
        CVOpenGLESTextureRef texture;
        glActiveTexture(gl_texture[i]);
        result = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                              _openGLESTextureCache,
                                                              pixelBuffer,
                                                              NULL,
                                                              GL_TEXTURE_2D,
                                                              internalFormats[i],
                                                              widths[i],
                                                              heights[i],
                                                              formats[i],
                                                              GL_UNSIGNED_BYTE,
                                                              i,
                                                              &texture);
        if (result == kCVReturnSuccess) {
            glBindTexture(CVOpenGLESTextureGetTarget(texture), CVOpenGLESTextureGetName(texture));
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        }
        if (texture) {
            CFRelease(texture);
            texture = NULL;
        }
        if (result != kCVReturnSuccess) {
            success = NO;
            break;
        }
    }
    CVPixelBufferRelease(pixelBuffer);
    return YES;
}

@end
