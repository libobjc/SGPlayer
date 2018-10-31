//
//  SGMapping.m
//  SGPlayer
//
//  Created by Single on 2018/1/26.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGMapping.h"

SGGLModelType SGDisplay2Model(SGDisplayMode displayMode)
{
    switch (displayMode) {
        case SGDisplayModePlane:
            return SGGLModelTypePlane;
        case SGDisplayModeVR:
        case SGDisplayModeVRBox:
            return SGGLModelTypeSphere;
    }
    return SGGLModelTypePlane;
}

SGGLProgramType SGFormat2Program(enum AVPixelFormat format, CVPixelBufferRef pixelBuffer)
{
    if (format == AV_PIX_FMT_VIDEOTOOLBOX && pixelBuffer) {
        format = SGPixelFormatAV2FF(CVPixelBufferGetPixelFormatType(pixelBuffer));
    }
    switch (format) {
        case AV_PIX_FMT_YUV420P:
            return SGGLProgramTypeYUV420P;
        case AV_PIX_FMT_NV12:
            return SGGLProgramTypeNV12;
        case AV_PIX_FMT_BGRA:
            return SGGLProgramTypeBGRA;
        default:
            return SGGLProgramTypeUnknown;
    }
}

SGGLTextureType SGFormat2Texture(enum AVPixelFormat format, CVPixelBufferRef pixelBuffer)
{
    if (format == AV_PIX_FMT_VIDEOTOOLBOX && pixelBuffer) {
        format = SGPixelFormatAV2FF(CVPixelBufferGetPixelFormatType(pixelBuffer));
    }
    switch (format) {
        case AV_PIX_FMT_YUV420P:
            return SGGLTextureTypeYUV420P;
        case AV_PIX_FMT_NV12:
            return SGGLTextureTypeNV12;
        default:
            return SGGLTextureTypeUnknown;
    }
}

SGGLViewportMode SGScaling2Viewport(SGScalingMode scalingMode)
{
    switch (scalingMode) {
        case SGScalingModeResize:
            return SGGLViewportModeResize;
        case SGScalingModeResizeAspect:
            return SGGLViewportModeResizeAspect;
        case SGScalingModeResizeAspectFill:
            return SGGLViewportModeResizeAspectFill;
    }
    return SGGLViewportModeResizeAspect;
}

SGMediaType SGMediaTypeFF2SG(enum AVMediaType mediaType)
{
    switch (mediaType) {
        case AVMEDIA_TYPE_AUDIO:
            return SGMediaTypeAudio;
        case AVMEDIA_TYPE_VIDEO:
            return SGMediaTypeVideo;
        case AVMEDIA_TYPE_SUBTITLE:
            return SGMediaTypeSubtitle;
        default:
            return SGMediaTypeUnknown;
    }
}

enum AVMediaType SGMediaTypeSG2FF(SGMediaType mediaType)
{
    switch (mediaType) {
        case SGMediaTypeAudio:
            return AVMEDIA_TYPE_AUDIO;
        case SGMediaTypeVideo:
            return AVMEDIA_TYPE_VIDEO;
        case SGMediaTypeSubtitle:
            return AVMEDIA_TYPE_SUBTITLE;
        default:
            return AVMEDIA_TYPE_UNKNOWN;
    }
}

OSType SGPixelFormatFF2AV(enum AVPixelFormat format)
{
    switch (format) {
        case AV_PIX_FMT_MONOBLACK:
            return kCVPixelFormatType_1Monochrome;
        case AV_PIX_FMT_RGB555BE:
            return kCVPixelFormatType_16BE555;
        case AV_PIX_FMT_RGB555LE:
            return kCVPixelFormatType_16LE555;
        case AV_PIX_FMT_RGB565BE:
            return kCVPixelFormatType_16BE565;
        case AV_PIX_FMT_RGB565LE:
            return kCVPixelFormatType_16LE565;
        case AV_PIX_FMT_RGB24:
            return kCVPixelFormatType_24RGB;
        case AV_PIX_FMT_BGR24:
            return kCVPixelFormatType_24BGR;
        case AV_PIX_FMT_0RGB:
            return kCVPixelFormatType_32ARGB;
        case AV_PIX_FMT_BGR0:
            return kCVPixelFormatType_32BGRA;
        case AV_PIX_FMT_0BGR:
            return kCVPixelFormatType_32ABGR;
        case AV_PIX_FMT_RGB0:
            return kCVPixelFormatType_32RGBA;
        case AV_PIX_FMT_BGR48BE:
            return kCVPixelFormatType_48RGB;
        case AV_PIX_FMT_UYVY422:
            return kCVPixelFormatType_422YpCbCr8;
        case AV_PIX_FMT_YUVA444P:
            return kCVPixelFormatType_4444YpCbCrA8R;
        case AV_PIX_FMT_YUVA444P16LE:
            return kCVPixelFormatType_4444AYpCbCr16;
        case AV_PIX_FMT_YUV444P:
            return kCVPixelFormatType_444YpCbCr8;
        case AV_PIX_FMT_YUV422P16:
            return kCVPixelFormatType_422YpCbCr16;
        case AV_PIX_FMT_YUV422P10:
            return kCVPixelFormatType_422YpCbCr10;
        case AV_PIX_FMT_YUV444P10:
            return kCVPixelFormatType_444YpCbCr10;
        case AV_PIX_FMT_YUV420P:
            return kCVPixelFormatType_420YpCbCr8Planar;
        case AV_PIX_FMT_NV12:
            return kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
        case AV_PIX_FMT_YUYV422:
            return kCVPixelFormatType_422YpCbCr8_yuvs;
        case AV_PIX_FMT_GRAY8:
            return kCVPixelFormatType_OneComponent8;
        default:
            return 0;
    }
    return 0;
}

enum AVPixelFormat SGPixelFormatAV2FF(OSType format)
{
    switch (format) {
        case kCVPixelFormatType_1Monochrome:
            return AV_PIX_FMT_MONOBLACK;
        case kCVPixelFormatType_16BE555:
            return AV_PIX_FMT_RGB555BE;
        case kCVPixelFormatType_16LE555:
            return AV_PIX_FMT_RGB555LE;
        case kCVPixelFormatType_16BE565:
            return AV_PIX_FMT_RGB565BE;
        case kCVPixelFormatType_16LE565:
            return AV_PIX_FMT_RGB565LE;
        case kCVPixelFormatType_24RGB:
            return AV_PIX_FMT_RGB24;
        case kCVPixelFormatType_24BGR:
            return AV_PIX_FMT_BGR24;
        case kCVPixelFormatType_32ARGB:
            return AV_PIX_FMT_0RGB;
        case kCVPixelFormatType_32BGRA:
            return AV_PIX_FMT_BGR0;
        case kCVPixelFormatType_32ABGR:
            return AV_PIX_FMT_0BGR;
        case kCVPixelFormatType_32RGBA:
            return AV_PIX_FMT_RGB0;
        case kCVPixelFormatType_48RGB:
            return AV_PIX_FMT_BGR48BE;
        case kCVPixelFormatType_422YpCbCr8:
            return AV_PIX_FMT_UYVY422;
        case kCVPixelFormatType_4444YpCbCrA8R:
            return AV_PIX_FMT_YUVA444P;
        case kCVPixelFormatType_4444AYpCbCr16:
            return AV_PIX_FMT_YUVA444P16LE;
        case kCVPixelFormatType_444YpCbCr8:
            return AV_PIX_FMT_YUV444P;
        case kCVPixelFormatType_422YpCbCr16:
            return AV_PIX_FMT_YUV422P16;
        case kCVPixelFormatType_422YpCbCr10:
            return AV_PIX_FMT_YUV422P10;
        case kCVPixelFormatType_444YpCbCr10:
            return AV_PIX_FMT_YUV444P10;
        case kCVPixelFormatType_420YpCbCr8Planar:
            return AV_PIX_FMT_YUV420P;
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            return AV_PIX_FMT_NV12;
        case kCVPixelFormatType_422YpCbCr8_yuvs:
            return AV_PIX_FMT_YUYV422;
        case kCVPixelFormatType_OneComponent8:
            return AV_PIX_FMT_GRAY8;
        default:
            return AV_PIX_FMT_NONE;
    }
    return AV_PIX_FMT_NONE;
}

AVDictionary * SGDictionaryNS2FF(NSDictionary * dictionary)
{
    __block AVDictionary * ret = NULL;
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSNumber class]]) {
            av_dict_set_int(&ret, [key UTF8String], [obj integerValue], 0);
        } else if ([obj isKindOfClass:[NSString class]]) {
            av_dict_set(&ret, [key UTF8String], [obj UTF8String], 0);
        }
    }];
    return ret;
}

NSDictionary * SGDictionaryFF2NS(AVDictionary * dictionary)
{
    NSMutableDictionary * ret = [NSMutableDictionary dictionary];
    AVDictionaryEntry * entry = NULL;
    while ((entry = av_dict_get(dictionary, "", entry, AV_DICT_IGNORE_SUFFIX))) {
        NSString * key = [NSString stringWithUTF8String:entry->key];
        NSString * value = [NSString stringWithUTF8String:entry->value];
        [ret setObject:value forKey:key];
    }
    if (ret.count <= 0) {
        ret = nil;
    }
    return [ret copy];
}
