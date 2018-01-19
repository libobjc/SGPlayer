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
#import "SGFFError.h"
#import "SGFFTime.h"

@interface SGFFCodecManager ()

@end

@implementation SGFFCodecManager

- (id <SGFFCodec>)codecForStream:(AVStream *)stream
{
    switch (stream->codecpar->codec_type)
    {
        case AVMEDIA_TYPE_VIDEO:
        {
            SGFFVideoCodec * videoCodec = [[SGFFVideoCodec alloc] init];
            videoCodec.timebase = SGFFTimebaseValidate(stream->time_base, 1, 25000);
            videoCodec.codecpar = stream->codecpar;
            return videoCodec;
        }
            break;
        case AVMEDIA_TYPE_AUDIO:
        {
            SGFFAudioCodec * audioCodec = [[SGFFAudioCodec alloc] init];
            audioCodec.timebase = SGFFTimebaseValidate(stream->time_base, 1, 44100);
            audioCodec.codecpar = stream->codecpar;
            return audioCodec;
        }
            break;
        default:
            break;
    }
    return nil;
}

@end
