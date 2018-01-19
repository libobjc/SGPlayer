//
//  SGFFAudioCodec.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioCodec.h"

@interface SGFFAudioCodec ()

@end

@implementation SGFFAudioCodec

+ (SGFFCodecType)type
{
    return SGFFCodecTypeAudio;
}

+ (AVRational)defaultTimebase
{
    static AVRational timabase = {1, 44100};
    return timabase;
}

@end
