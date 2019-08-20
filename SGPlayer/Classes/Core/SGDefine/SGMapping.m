//
//  SGMapping.m
//  SGPlayer
//
//  Created by Single on 2018/1/26.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGMapping.h"

SGMetalViewportMode SGScaling2Viewport(SGScalingMode mode)
{
    switch (mode) {
        case SGScalingModeResize:
            return SGMetalViewportModeResize;
        case SGScalingModeResizeAspect:
            return SGMetalViewportModeResizeAspect;
        case SGScalingModeResizeAspectFill:
            return SGMetalViewportModeResizeAspectFill;
    }
    return SGMetalViewportModeResizeAspect;
}

SGScalingMode SGViewport2Scaling(SGMetalViewportMode mode)
{
    switch (mode) {
        case SGMetalViewportModeResize:
            return SGScalingModeResize;
        case SGMetalViewportModeResizeAspect:
            return SGScalingModeResizeAspect;
        case SGMetalViewportModeResizeAspectFill:
            return SGScalingModeResizeAspectFill;
    }
    return SGScalingModeResizeAspect;
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
        case AV_PIX_FMT_YUV420P:
            return kCVPixelFormatType_420YpCbCr8Planar;
        case AV_PIX_FMT_UYVY422:
            return kCVPixelFormatType_422YpCbCr8;
        case AV_PIX_FMT_BGRA:
            return kCVPixelFormatType_32BGRA;
        case AV_PIX_FMT_NV12:
            return kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
        default:
            return 0;
    }
    return 0;
}

enum AVPixelFormat SGPixelFormatAV2FF(OSType format)
{
    switch (format) {
        case kCVPixelFormatType_420YpCbCr8Planar:
            return AV_PIX_FMT_YUV420P;
        case kCVPixelFormatType_422YpCbCr8:
            return AV_PIX_FMT_UYVY422;
        case kCVPixelFormatType_32BGRA:
            return AV_PIX_FMT_BGRA;
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            return AV_PIX_FMT_NV12;
        default:
            return AV_PIX_FMT_NONE;
    }
    return AV_PIX_FMT_NONE;
}

AVDictionary * SGDictionaryNS2FF(NSDictionary *dictionary)
{
    __block AVDictionary *ret = NULL;
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSNumber class]]) {
            av_dict_set_int(&ret, [key UTF8String], [obj integerValue], 0);
        } else if ([obj isKindOfClass:[NSString class]]) {
            av_dict_set(&ret, [key UTF8String], [obj UTF8String], 0);
        }
    }];
    return ret;
}

NSDictionary * SGDictionaryFF2NS(AVDictionary *dictionary)
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    AVDictionaryEntry *entry = NULL;
    while ((entry = av_dict_get(dictionary, "", entry, AV_DICT_IGNORE_SUFFIX))) {
        NSString *key = [NSString stringWithUTF8String:entry->key];
        NSString *value = [NSString stringWithUTF8String:entry->value];
        [ret setObject:value forKey:key];
    }
    if (ret.count <= 0) {
        ret = nil;
    }
    return [ret copy];
}
