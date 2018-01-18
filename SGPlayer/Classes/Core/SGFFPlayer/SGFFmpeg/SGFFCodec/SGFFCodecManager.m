//
//  SGFFCodecManager.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFCodecManager.h"
#import "SGFFVideoCodec.h"
#import "SGFFAudioCodec.h"
#import "SGFFUtil.h"

@interface SGFFCodecManager ()

@end

@implementation SGFFCodecManager

- (id <SGFFCodec>)codecForStream:(AVStream *)stream
{
    switch (stream->codecpar->codec_type)
    {
        case AVMEDIA_TYPE_VIDEO:
        {
            AVCodecContext * codecContext = [self codecContextWithStream:stream];
            if (codecContext)
            {
                SGFFVideoCodec * videoCodec = [[SGFFVideoCodec alloc] init];
                videoCodec.codecContext = codecContext;
                return videoCodec;
            }
        }
            break;
        case AVMEDIA_TYPE_AUDIO:
        {
            AVCodecContext * codecContext = [self codecContextWithStream:stream];
            if (codecContext)
            {
                SGFFAudioCodec * audioCodec = [[SGFFAudioCodec alloc] init];
                audioCodec.codecContext = codecContext;
                return audioCodec;
            }
        }
            break;
        default:
            break;
    }
    return nil;
}

- (AVCodecContext *)codecContextWithStream:(AVStream *)stream
{
    AVCodecContext * codecContext = avcodec_alloc_context3(NULL);
    if (!codecContext)
    {
        return nil;
    }
    
    int result = avcodec_parameters_to_context(codecContext, stream->codecpar);
    NSError * error = SGFFGetError(result);
    if (error)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    av_codec_set_pkt_timebase(codecContext, stream->time_base);
    
    AVCodec * codec = avcodec_find_decoder(codecContext->codec_id);
    if (!codec)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    codecContext->codec_id = codec->id;
    
    result = avcodec_open2(codecContext, codec, NULL);
    error = SGFFGetError(result);
    if (error)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    
    return codecContext;
}

@end
