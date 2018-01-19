//
//  SGFFCodecManager.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFCodecManager.h"
#import "SGFFVideoAVCodec.h"
#import "SGFFAudioAVCodec.h"
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
            SGFFVideoAVCodec * videoCodec = [[SGFFVideoAVCodec alloc] init];
            videoCodec.timebase = SGFFTimebaseValidate(stream->time_base.num, stream->time_base.den, 1, 25000);
            videoCodec.codecpar = stream->codecpar;
            return videoCodec;
        }
            break;
        case AVMEDIA_TYPE_AUDIO:
        {
            SGFFAudioAVCodec * audioCodec = [[SGFFAudioAVCodec alloc] init];
            audioCodec.timebase = SGFFTimebaseValidate(stream->time_base.num, stream->time_base.den, 1, 44100);
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
