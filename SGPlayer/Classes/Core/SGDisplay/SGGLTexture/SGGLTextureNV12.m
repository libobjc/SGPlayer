//
//  SGGLTextureNV12.m
//  SGPlayer
//
//  Created by Single on 2017/3/27.
//  Copyright © 2017年 single. All rights reserved.
//

#import <SGPlatform/SGPlatform.h>
#import "SGGLTextureNV12.h"
#import "SGPlayerMacro.h"
#import "SGYUVTools.h"

#if SGPLATFORM_TARGET_OS_MAC

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

@interface SGGLTextureNV12 ()

{
    UInt8 * _texture_data_y;
    UInt8 * _texture_data_uv;
    size_t _texture_datasize_y;
    size_t _texture_datasize_uv;
}

@property (nonatomic, assign) CGFloat textureAspect;
@property (nonatomic, assign) BOOL didBindTexture;

@end

@implementation SGGLTextureNV12

static GLuint texture_id_y = 0;
static GLuint texture_id_uv = 0;

- (instancetype)initWithContext:(SGPLFGLContext *)context
{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            glGenTextures(1, &texture_id_y);
            glGenTextures(1, &texture_id_uv);
        });
    }
    return self;
}

- (BOOL)updateTextureWithGLFrame:(SGGLFrame *)glFrame aspect:(CGFloat *)aspect
{
    CVPixelBufferRef pixelBuffer = [glFrame pixelBufferForNV12];
    if (pixelBuffer == nil) {
        if (self.didBindTexture) {
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, texture_id_y);
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, texture_id_uv);
            * aspect = self.textureAspect;
            return YES;
        } else {
            return NO;
        }
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    void * data_y = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    int linesize_y = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    int width_y = (int)CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    int height_y = (int)CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    
    self.textureAspect = (width_y * 1.0) / (height_y * 1.0);
    * aspect = self.textureAspect;
    
    void * data_uv = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    int linesize_uv = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    int width_uv = (int)CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    int height_uv = (int)CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    
    size_t size_y = SGYUVChannelFilterNeedSize(linesize_y, width_y, height_y, 1);
    if (_texture_datasize_y < size_y) {
        if (_texture_datasize_y > 0 && _texture_data_y != NULL) {
            free(_texture_data_y);
        }
        _texture_datasize_y = size_y;
        _texture_data_y = malloc(_texture_datasize_y);
    }
    size_t size_uv = SGYUVChannelFilterNeedSize(linesize_uv, width_uv, height_uv, 2);
    if (_texture_datasize_uv < size_uv) {
        if (_texture_datasize_uv > 0 && _texture_data_uv != NULL) {
            free(_texture_data_uv);
        }
        _texture_datasize_uv = size_uv;
        _texture_data_uv = malloc(_texture_datasize_uv);
    }
    
    SGYUVChannelFilter(data_y, linesize_y, width_y, height_y, _texture_data_y, _texture_datasize_y, 1);
    SGYUVChannelFilter(data_uv, linesize_uv, width_uv, height_uv, _texture_data_uv, _texture_datasize_uv, 2);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture_id_y);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width_y, height_y, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, _texture_data_y);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glActiveTexture(GL_TEXTURE0);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, texture_id_uv);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, width_uv, height_uv, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, _texture_data_uv);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glActiveTexture(GL_TEXTURE1);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    self.didBindTexture = YES;
    return YES;
}

- (void)cleanTextures
{
    if (_texture_datasize_y > 0 && _texture_data_y != NULL) {
        free(_texture_data_y);
    }
    if (_texture_datasize_uv > 0 && _texture_data_uv != NULL) {
        free(_texture_data_uv);
    }
    _texture_data_y = NULL;
    _texture_data_uv = NULL;
    _texture_datasize_y = 0;
    _texture_datasize_uv = 0;
}

- (void)dealloc
{
    [self cleanTextures];
    SGPlayerLog(@"SGGLAVTexture release");
}

@end

#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface SGGLTextureNV12 ()

@property (nonatomic, strong) SGPLFGLContext * context;

@property (nonatomic, assign) CVOpenGLESTextureRef lumaTexture;
@property (nonatomic, assign) CVOpenGLESTextureRef chromaTexture;
@property (nonatomic, assign) CVOpenGLESTextureCacheRef videoTextureCache;

@property (nonatomic, assign) CGFloat textureAspect;
@property (nonatomic, assign) BOOL didBindTexture;

@end

@implementation SGGLTextureNV12

- (instancetype)initWithContext:(SGPLFGLContext *)context
{
    if (self = [super init]) {
        self.context = context;
        [self setupVideoCache];
    }
    return self;
}

- (void)setupVideoCache
{
    if (!self.videoTextureCache) {
        CVReturn result = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_videoTextureCache);
        if (result != noErr) {
            SGPlayerLog(@"create CVOpenGLESTextureCacheCreate failure %d", result);
            return;
        }
    }
}

- (BOOL)updateTextureWithGLFrame:(SGGLFrame *)glFrame aspect:(CGFloat *)aspect
{
    CVPixelBufferRef pixelBuffer = [glFrame pixelBufferForNV12];
    if (pixelBuffer == nil) {
        if (self.lumaTexture && self.chromaTexture) {
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(CVOpenGLESTextureGetTarget(self.lumaTexture), CVOpenGLESTextureGetName(self.lumaTexture));
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(CVOpenGLESTextureGetTarget(self.chromaTexture), CVOpenGLESTextureGetName(self.chromaTexture));
            * aspect = self.textureAspect;
            return YES;
        } else {
            return NO;
        }
    }
    
    if (!self.videoTextureCache) {
        SGPlayerLog(@"no video texture cache");
        return NO;
    }
    
    GLsizei textureWidth = (GLsizei)CVPixelBufferGetWidth(pixelBuffer);
    GLsizei textureHeight = (GLsizei)CVPixelBufferGetHeight(pixelBuffer);
    self.textureAspect = (textureWidth * 1.0) / (textureHeight * 1.0);
    * aspect = self.textureAspect;
    
    [self cleanTextures];
    
    CVReturn result;
    // Y-plane
    glActiveTexture(GL_TEXTURE0);
    result = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          self.videoTextureCache,
                                                          pixelBuffer,
                                                          NULL,
                                                          GL_TEXTURE_2D,
                                                          GL_RED_EXT,
                                                          textureWidth,
                                                          textureHeight,
                                                          GL_RED_EXT,
                                                          GL_UNSIGNED_BYTE,
                                                          0,
                                                          &_lumaTexture);
    
    if (result == kCVReturnSuccess) {
        glBindTexture(CVOpenGLESTextureGetTarget(self.lumaTexture), CVOpenGLESTextureGetName(self.lumaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    } else {
        SGPlayerLog(@"create CVOpenGLESTextureCacheCreateTextureFromImage failure 1 %d", result);
    }
    
    // UV-plane.
    glActiveTexture(GL_TEXTURE1);
    result = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          self.videoTextureCache,
                                                          pixelBuffer,
                                                          NULL,
                                                          GL_TEXTURE_2D,
                                                          GL_RG_EXT,
                                                          textureWidth/2,
                                                          textureHeight/2,
                                                          GL_RG_EXT,
                                                          GL_UNSIGNED_BYTE,
                                                          1,
                                                          &_chromaTexture);
    
    if (result == kCVReturnSuccess) {
        glBindTexture(CVOpenGLESTextureGetTarget(self.chromaTexture), CVOpenGLESTextureGetName(self.chromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    } else {
        SGPlayerLog(@"create CVOpenGLESTextureCacheCreateTextureFromImage failure 2 %d", result);
    }
    
    self.didBindTexture = YES;
    return YES;
}

- (void)clearVideoCache
{
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
        self.videoTextureCache = nil;
    }
}

- (void)cleanTextures
{
    if (self.lumaTexture) {
        CFRelease(_lumaTexture);
        self.lumaTexture = NULL;
    }
    
    if (self.chromaTexture) {
        CFRelease(_chromaTexture);
        self.chromaTexture = NULL;
    }
    
    self.textureAspect = 16.0 / 9.0;
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

- (void)dealloc
{
    [self clearVideoCache];
    [self cleanTextures];
    SGPlayerLog(@"SGAVGLTexture release");
}

@end

#endif

