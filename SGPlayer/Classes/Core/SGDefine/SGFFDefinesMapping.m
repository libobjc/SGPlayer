//
//  SGFFDefinesMapping.m
//  SGPlayer
//
//  Created by Single on 2018/1/26.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFDefinesMapping.h"

SGGLProgramType SGDMFormat2Program(SGAVPixelFormat format)
{
    switch (format)
    {
        case SG_AV_PIX_FMT_YUV420P:
            return SGGLProgramTypeYUV420P;
        case SG_AV_PIX_FMT_NV12:
            return SGGLProgramTypeNV12;
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
            return SGGLTextureTypeNV12;
        default:
            return SGGLTextureTypeUnknown;
    }
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
    return (SGAVPixelFormat)format;
}

SGAVColorRange SGDMColorRangeFF2SG(enum AVColorRange format)
{
    return (SGAVColorRange)format;
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

enum AVColorRange SGDMColorRangeSG2FF(SGAVColorRange foramt)
{
    return (enum AVColorRange)foramt;
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

enum AVChromaLocation SGDMChromaLocationSG2FF(SGAVChromaLocation foramt)
{
    return (enum AVChromaLocation)foramt;
}
