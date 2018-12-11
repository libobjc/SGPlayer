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
#import "SGFFmpeg.h"

static int gl_texture[3] = {
    GL_TEXTURE0,
    GL_TEXTURE1,
    GL_TEXTURE2,
};

@interface SGGLTextureUploader ()

{
    AVBufferRef *_resample_buffers[SGFramePlaneCount];
    GLuint _gl_texture_ids[3];
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    CVOpenGLESTextureCacheRef _openGLESTextureCache;
#endif
}

@property (nonatomic, strong) SGPLFGLContext *context;
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
@property (nonatomic) BOOL setupOpenGLESTextureCacheFailed;
#endif

@end

@implementation SGGLTextureUploader

- (instancetype)initWithGLContext:(SGPLFGLContext *)context
{
    if (self = [super init]) {
        self.context = context;
        for (int i = 0; i < 8; i++) {
            _resample_buffers[i] = nil;
        }
    }
    return self;
}

- (void)dealloc
{
    for (int i = 0; i < SGFramePlaneCount; i++) {
        av_buffer_unref(&_resample_buffers[i]);
        _resample_buffers[i] = nil;
    }
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
    SGVideoDescription *description = frame.videoDescription;
    uint8_t *data[SGFramePlaneCount] = {0};
    int linesize[SGFramePlaneCount] = {0};
    if (description.format == AV_PIX_FMT_VIDEOTOOLBOX && frame.pixelBuffer) {
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
        return [self uploadWithCVPixelBuffer:frame.pixelBuffer];
#else
        CVReturn err = CVPixelBufferLockBaseAddress(frame.pixelBuffer, kCVPixelBufferLock_ReadOnly);
        if (err != kCVReturnSuccess) {
            return NO;
        }
        description.format = SGPixelFormatAV2FF(CVPixelBufferGetPixelFormatType(frame.pixelBuffer));
        if (CVPixelBufferIsPlanar(frame.pixelBuffer)) {
            int planes = (int)CVPixelBufferGetPlaneCount(frame.pixelBuffer);
            for (int i = 0; i < planes; i++) {
                data[i]     = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(frame.pixelBuffer, i);
                linesize[i] = (int)CVPixelBufferGetBytesPerRowOfPlane(frame.pixelBuffer, i);
            }
        } else {
            data[0] = (uint8_t *)CVPixelBufferGetBaseAddress(frame.pixelBuffer);
            linesize[0] = (int)CVPixelBufferGetBytesPerRow(frame.pixelBuffer);
        }
        CVPixelBufferUnlockBaseAddress(frame.pixelBuffer, kCVPixelBufferLock_ReadOnly);
#endif
    } else {
        for (int i = 0; i < SGFramePlaneCount; i++) {
            data[i] = frame.data[i];
            linesize[i] = frame.linesize[i];
        }
    }
    return [self uploadWithFormat:description.format
                             data:data
                         linesize:linesize
                            width:description.width
                           height:description.height];
}

- (BOOL)uploadWithFormat:(enum AVPixelFormat)format data:(uint8_t **)data_src linesize:(int *)linesize_src width:(int)width height:(int)height
{
    uint8_t *data[SGFramePlaneCount] = {0};
    int linesize[SGFramePlaneCount] = {0};
    int widths[SGFramePlaneCount] = {0};
    int heights[SGFramePlaneCount] = {0};
    int formats[SGFramePlaneCount] = {0};
    int internalFormats[SGFramePlaneCount] = {0};
    int planes = 0;
    if (format == AV_PIX_FMT_YUV420P) {
        widths[0] = width;
        widths[1] = width / 2;
        widths[2] = width / 2;
        heights[0] = height;
        heights[1] = height / 2;
        heights[2] = height / 2;
        linesize[0] = sizeof(uint8_t) * 1 * width;
        linesize[1] = sizeof(uint8_t) * 1 * width / 2;
        linesize[2] = sizeof(uint8_t) * 1 * width / 2;
        formats[0] = GL_LUMINANCE;
        formats[1] = GL_LUMINANCE;
        formats[2] = GL_LUMINANCE;
        internalFormats[0] = GL_LUMINANCE;
        internalFormats[1] = GL_LUMINANCE;
        internalFormats[2] = GL_LUMINANCE;
        planes = 3;
    } else if (format == AV_PIX_FMT_NV12) {
        widths[0] = width;
        widths[1] = width / 2;
        heights[0] = height;
        heights[1] = height / 2;
        linesize[0] = sizeof(uint8_t) * 1 * width;
        linesize[1] = sizeof(uint8_t) * 1 * width;
        formats[0] = GL_LUMINANCE;
        internalFormats[0] = GL_LUMINANCE;
#if SGPLATFORM_TARGET_OS_MAC
        formats[1] = GL_LUMINANCE_ALPHA;
        internalFormats[1] = GL_LUMINANCE_ALPHA;
#else
        formats[1] = GL_RG_EXT;
        internalFormats[1] = GL_RG_EXT;
#endif
        planes = 2;
    } else if (format == AV_PIX_FMT_BGRA) {
        widths[0] = width;
        heights[0] = height;
        linesize[0] = sizeof(uint8_t) * 4 * width;
        formats[0] = GL_BGRA;
        internalFormats[0] = GL_RGBA;
        planes = 1;
    } else if (format == AV_PIX_FMT_RGBA) {
        widths[0] = width;
        heights[0] = height;
        linesize[0] = sizeof(uint8_t) * 4 * width;
        formats[0] = GL_RGBA;
        internalFormats[0] = GL_RGBA;
        planes = 1;
    } else {
        return NO;
    }
    BOOL resample = NO;
    for (int i = 0; i < planes; i++) {
        resample = resample || (linesize_src[i] != linesize[i]);
    }
    if (resample) {
        for (int i = 0; i < planes; i++) {
            int size = linesize[i] * heights[i] * sizeof(uint8_t);
            if (!_resample_buffers[i] || _resample_buffers[i]->size < size) {
                av_buffer_realloc(&_resample_buffers[i], size);
            }
            av_image_copy_plane(_resample_buffers[i]->data,
                                linesize[i],
                                data_src[i],
                                linesize_src[i],
                                linesize[i] * sizeof(uint8_t),
                                heights[i]);
            data[i] = _resample_buffers[i]->data;
        }
    } else {
        for (int i = 0; i < SGFramePlaneCount; i++) {
            data[i] = data_src[i];
            linesize[i] = linesize_src[i];
        }
    };
    return [self uploadWithData:data
                         widths:widths
                        heights:heights
                internalFormats:internalFormats
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
