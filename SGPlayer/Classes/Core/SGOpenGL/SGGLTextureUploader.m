//
//  SGGLTextureUploader.m
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLTextureUploader.h"
#import "SGPLFOpenGL.h"
#import "SGMapping.h"

static int gl_texture[3] = {
    GL_TEXTURE0,
    GL_TEXTURE1,
    GL_TEXTURE2,
};

@interface SGGLTextureUploader ()

{
    GLuint _gl_texture_ids[3];
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    CVOpenGLESTextureCacheRef _openGLESTextureCache;
#endif
}

@property (nonatomic, strong) SGPLFGLContext * context;
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
@property (nonatomic, assign) BOOL setupOpenGLESTextureCacheFailed;
#endif

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
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    if (_openGLESTextureCache) {
        CVOpenGLESTextureCacheFlush(_openGLESTextureCache, 0);
        CFRelease(_openGLESTextureCache);
        _openGLESTextureCache = NULL;
    }
#endif
}

- (void)setupGLTextureIfNeeded
{
    if (!_gl_texture_ids[0]) {
        glGenTextures(3, _gl_texture_ids);
    }
}

- (BOOL)uploadWithVideoFrame:(SGVideoFrame *)frame
{
    enum AVPixelFormat format = AV_PIX_FMT_NONE;
    uint8_t * data[SGFramePlaneCount] = {0};
    int linesize[SGFramePlaneCount] = {0};
    if (frame.format == AV_PIX_FMT_VIDEOTOOLBOX && frame->_pixelBuffer) {
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
        return [self uploadWithCVPixelBuffer:frame->_pixelBuffer];
#endif
        CVReturn err = CVPixelBufferLockBaseAddress(frame->_pixelBuffer, kCVPixelBufferLock_ReadOnly);
        if (err != kCVReturnSuccess) {
            return NO;
        }
        format = SGPixelFormatAV2FF(CVPixelBufferGetPixelFormatType(frame->_pixelBuffer));
        if (CVPixelBufferIsPlanar(frame->_pixelBuffer)) {
            int planes = (int)CVPixelBufferGetPlaneCount(frame->_pixelBuffer);
            for (int i = 0; i < planes; i++) {
                data[i]     = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(frame->_pixelBuffer, i);
                linesize[i] = (int)CVPixelBufferGetBytesPerRowOfPlane(frame->_pixelBuffer, i);
            }
        } else {
            data[0] = (uint8_t *)CVPixelBufferGetBaseAddress(frame->_pixelBuffer);
            linesize[0] = (int)CVPixelBufferGetBytesPerRow(frame->_pixelBuffer);
        }
        CVPixelBufferUnlockBaseAddress(frame->_pixelBuffer, kCVPixelBufferLock_ReadOnly);
    }
    return [self uploadWithFormat:format data:data linesize:linesize width:frame.width height:frame.height];
}

- (BOOL)uploadWithFormat:(enum AVPixelFormat)format data:(uint8_t **)data linesize:(int *)linesize width:(int)width height:(int)height
{
    int planes = 0;
    int widths[SGFramePlaneCount]  = {0};
    int heights[SGFramePlaneCount] = {0};
    int formats[SGFramePlaneCount] = {0};
    if (format == AV_PIX_FMT_YUV420P) {
        planes = 3;
        widths[0] = width;
        widths[1] = width / 2;
        widths[2] = width / 2;
        heights[0] = height;
        heights[1] = height / 2;
        heights[2] = height / 2;
        formats[0] = GL_LUMINANCE;
        formats[1] = GL_LUMINANCE;
        formats[2] = GL_LUMINANCE;
    } else if (format == AV_PIX_FMT_NV12) {
        planes = 2;
        widths[0] = width;
        widths[1] = width / 2;
        heights[0] = height;
        heights[1] = height / 2;
        formats[0] = GL_LUMINANCE;
        formats[1] = GL_LUMINANCE_ALPHA;
    } else {
        return NO;
    }
    return [self uploadWithData:data
                         widths:widths
                        heights:heights
                internalFormats:formats
                        formats:formats
                          count:planes];
}

- (BOOL)uploadWithData:(uint8_t **)data
                widths:(int *)widths
               heights:(int *)heights
       internalFormats:(int *)internalFormats
               formats:(int *)formats
                 count:(int)count
{
    [self setupGLTextureIfNeeded];
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

#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
- (void)setupOpenGLESTextureCacheIfNeeded
{
    if (!_openGLESTextureCache && !self.setupOpenGLESTextureCacheFailed) {
        CVReturn result = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_openGLESTextureCache);
        if (result != noErr) {
            self.setupOpenGLESTextureCacheFailed = YES;
        }
    }
}

- (BOOL)uploadWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    [self setupOpenGLESTextureCacheIfNeeded];
    if (!_openGLESTextureCache) {
        return NO;
    }
    CVOpenGLESTextureCacheFlush(_openGLESTextureCache, 0);
    OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);
    GLsizei width = (int)CVPixelBufferGetWidth(pixelBuffer);
    GLsizei height = (int)CVPixelBufferGetHeight(pixelBuffer);
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
#endif

@end
