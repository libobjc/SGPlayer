//
//  SGFFDefinesMapping.m
//  SGPlayer
//
//  Created by Single on 2018/1/26.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFDefinesMapping.h"

SGGLModelType SGDMDisplay2Model(SGDisplayMode displayMode)
{
    switch (displayMode)
    {
        case SGDisplayModePlane:
            return SGGLModelTypePlane;
        case SGDisplayModeVR:
        case SGDisplayModeVRBox:
            return SGGLModelTypeSphere;
    }
    return SGGLModelTypePlane;
}

SGGLProgramType SGDMFormat2Program(SGAVPixelFormat format)
{
    switch (format)
    {
        case SG_AV_PIX_FMT_YUV420P:
            return SGGLProgramTypeYUV420P;
        case SG_AV_PIX_FMT_NV12:
        case SG_AV_PIX_FMT_VIDEOTOOLBOX:
            return SGGLProgramTypeNV12;
        case SG_AV_PIX_FMT_BGRA:
            return SGGLProgramTypeBGRA;
        default:
            return SGGLProgramTypeUnknown;
    }
}

SGGLTextureType SGDMFormat2Texture(SGAVPixelFormat format)
{
    switch (format)
    {
        case SG_AV_PIX_FMT_YUV420P:
            return SGGLTextureTypeYUV420P;
        case SG_AV_PIX_FMT_NV12:
        case SG_AV_PIX_FMT_VIDEOTOOLBOX:
            return SGGLTextureTypeNV12;
        default:
            return SGGLTextureTypeUnknown;
    }
}

SGGLViewportMode SGDMScaling2Viewport(SGScalingMode scalingMode)
{
    switch (scalingMode)
    {
        case SGScalingModeResize:
            return SGGLViewportModeResize;
        case SGScalingModeResizeAspect:
            return SGGLViewportModeResizeAspect;
        case SGScalingModeResizeAspectFill:
            return SGGLViewportModeResizeAspectFill;
    }
    return SGGLViewportModeResizeAspect;
}

SGMediaType SGDMMediaTypeFF2SG(enum AVMediaType mediaType)
{
    switch (mediaType)
    {
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

SGAVSampleFormat SGDMSampleFormatFF2SG(enum AVSampleFormat format)
{
    return (SGAVSampleFormat)format;
}

SGAVPixelFormat SGDMPixelFormatFF2SG(enum AVPixelFormat format)
{
    switch (format)
    {
        case AV_PIX_FMT_VIDEOTOOLBOX:
            return SG_AV_PIX_FMT_VIDEOTOOLBOX;
        default:
            break;
    }
    return (SGAVPixelFormat)format;
}

SGAVColorPrimaries SGDMColorPrimariesFF2SG(enum AVColorPrimaries format)
{
    return (SGAVColorPrimaries)format;
}

SGAVColorTransferCharacteristic SGDMColorTransferCharacteristicFF2SG(enum AVColorTransferCharacteristic format)
{
    return (SGAVColorTransferCharacteristic)format;
}

SGAVColorSpace SGDMColorSpaceFF2SG(enum AVColorSpace format)
{
    return (SGAVColorSpace)format;
}

SGAVColorRange SGDMColorRangeFF2SG(enum AVColorRange format)
{
    return (SGAVColorRange)format;
}

SGAVChromaLocation SGDMChromaLocationFF2SG(enum AVChromaLocation format)
{
    return (SGAVChromaLocation)format;
}

enum AVMediaType SGDMMediaTypeSG2FF(SGMediaType mediaType)
{
    switch (mediaType)
    {
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

enum AVSampleFormat SGDMSampleFormatSG2FF(SGAVSampleFormat foramt)
{
    return (enum AVSampleFormat)foramt;
}

enum AVPixelFormat SGDMPixelFormatSG2FF(SGAVPixelFormat foramt)
{
    return (enum AVPixelFormat)foramt;
}

enum AVColorPrimaries SGDMColorPrimariesSG2FF(SGAVColorPrimaries foramt)
{
    return (enum AVColorPrimaries)foramt;
}

enum AVColorTransferCharacteristic SGDMColorTransferCharacteristicSG2FF(SGAVColorTransferCharacteristic foramt)
{
    return (enum AVColorTransferCharacteristic)foramt;
}

enum AVColorSpace SGDMColorSpaceSG2FF(SGAVColorSpace foramt)
{
    return (enum AVColorSpace)foramt;
}

enum AVColorRange SGDMColorRangeSG2FF(SGAVColorRange foramt)
{
    return (enum AVColorRange)foramt;
}

enum AVChromaLocation SGDMChromaLocationSG2FF(SGAVChromaLocation foramt)
{
    return (enum AVChromaLocation)foramt;
}

OSType SGDMPixelFormatSG2AV(SGAVPixelFormat format)
{
    switch (format)
    {
        case SG_AV_PIX_FMT_NV12:
            return kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
        case SG_AV_PIX_FMT_YUV420P:
            return kCVPixelFormatType_420YpCbCr8Planar;
        case SG_AV_PIX_FMT_UYVY422:
            return kCVPixelFormatType_422YpCbCr8;
        case SG_AV_PIX_FMT_BGRA:
            return kCVPixelFormatType_32BGRA;
        case SG_AV_PIX_FMT_RGBA:
            return kCVPixelFormatType_32RGBA;
        default:
            return 0;
    }
    return 0;
}

SGAVPixelFormat SGDMPixelFormatAV2SG(OSType format)
{
    switch (format)
    {
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            return SG_AV_PIX_FMT_NV12;
        case kCVPixelFormatType_420YpCbCr8Planar:
            return SG_AV_PIX_FMT_YUV420P;
        case kCVPixelFormatType_422YpCbCr8:
            return SG_AV_PIX_FMT_UYVY422;
        case kCVPixelFormatType_32BGRA:
            return SG_AV_PIX_FMT_BGRA;
        case kCVPixelFormatType_32RGBA:
            return SG_AV_PIX_FMT_RGBA;
        default:
            return SG_AV_PIX_FMT_NONE;
    }
    return SG_AV_PIX_FMT_NONE;
}
