//
//  SGFFDefinesMapping.m
//  SGPlayer
//
//  Created by Single on 2018/1/26.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFDefinesMapping.h"

SGMediaType SGFFMediaType(enum AVMediaType mediaType)
{
    if (mediaType == AVMEDIA_TYPE_AUDIO) {
        return SGMediaTypeAudio;
    } else if (mediaType == AVMEDIA_TYPE_VIDEO) {
        return SGMediaTypeVideo;
    } else if (mediaType == AVMEDIA_TYPE_SUBTITLE) {
        return SGMediaTypeSubtitle;
    }
    return SGMediaTypeUnknown;
}

SGGLProgramType SGFFDMProgram(enum AVPixelFormat format)
{
    if (format == AV_PIX_FMT_YUV420P) {
        return SGGLProgramTypeYUV420P;
    } else if (format == AV_PIX_FMT_NV12) {
        return SGGLProgramTypeNV12;
    }
    return SGGLProgramTypeUnknown;
}

SGGLTextureType SGFFDMTexture(enum AVPixelFormat format)
{
    if (format == AV_PIX_FMT_YUV420P) {
        return SGGLTextureTypeYUV420P;
    } else if (format == AV_PIX_FMT_NV12) {
        return SGGLTextureTypeNV12;
    }
    return SGGLTextureTypeUnknown;
}

SGAVSampleFormat SGSampleFormatFF2SG(enum AVSampleFormat format)
{
    switch (format)
    {
        case AV_SAMPLE_FMT_NONE:
            return SG_AV_SAMPLE_FMT_NONE;
        case AV_SAMPLE_FMT_U8:
            return SG_AV_SAMPLE_FMT_U8;
        case AV_SAMPLE_FMT_S16:
            return SG_AV_SAMPLE_FMT_S16;
        case AV_SAMPLE_FMT_S32:
            return SG_AV_SAMPLE_FMT_S32;
        case AV_SAMPLE_FMT_FLT:
            return SG_AV_SAMPLE_FMT_FLT;
        case AV_SAMPLE_FMT_DBL:
            return SG_AV_SAMPLE_FMT_DBL;
        case AV_SAMPLE_FMT_U8P:
            return SG_AV_SAMPLE_FMT_U8P;
        case AV_SAMPLE_FMT_S16P:
            return SG_AV_SAMPLE_FMT_S16P;
        case AV_SAMPLE_FMT_S32P:
            return SG_AV_SAMPLE_FMT_S32P;
        case AV_SAMPLE_FMT_FLTP:
            return SG_AV_SAMPLE_FMT_FLTP;
        case AV_SAMPLE_FMT_DBLP:
            return SG_AV_SAMPLE_FMT_DBLP;
        case AV_SAMPLE_FMT_S64:
            return SG_AV_SAMPLE_FMT_S64;
        case AV_SAMPLE_FMT_S64P:
            return SG_AV_SAMPLE_FMT_S64P;
        case AV_SAMPLE_FMT_NB:
            return SG_AV_SAMPLE_FMT_NB;
    }
    return SG_AV_SAMPLE_FMT_NONE;
}

enum AVSampleFormat SGSampleFormatSG2FF(SGAVSampleFormat froamt)
{
    switch (froamt)
    {
        case SG_AV_SAMPLE_FMT_NONE:
            return AV_SAMPLE_FMT_NONE;
        case SG_AV_SAMPLE_FMT_U8:
            return AV_SAMPLE_FMT_U8;
        case SG_AV_SAMPLE_FMT_S16:
            return AV_SAMPLE_FMT_S16;
        case SG_AV_SAMPLE_FMT_S32:
            return AV_SAMPLE_FMT_S32;
        case SG_AV_SAMPLE_FMT_FLT:
            return AV_SAMPLE_FMT_FLT;
        case SG_AV_SAMPLE_FMT_DBL:
            return AV_SAMPLE_FMT_DBL;
        case SG_AV_SAMPLE_FMT_U8P:
            return AV_SAMPLE_FMT_U8P;
        case SG_AV_SAMPLE_FMT_S16P:
            return AV_SAMPLE_FMT_S16P;
        case SG_AV_SAMPLE_FMT_S32P:
            return AV_SAMPLE_FMT_S32P;
        case SG_AV_SAMPLE_FMT_FLTP:
            return AV_SAMPLE_FMT_FLTP;
        case SG_AV_SAMPLE_FMT_DBLP:
            return AV_SAMPLE_FMT_DBLP;
        case SG_AV_SAMPLE_FMT_S64:
            return AV_SAMPLE_FMT_S64;
        case SG_AV_SAMPLE_FMT_S64P:
            return AV_SAMPLE_FMT_S64P;
        case SG_AV_SAMPLE_FMT_NB:
            return AV_SAMPLE_FMT_NB;
    }
    return AV_SAMPLE_FMT_NONE;
}
