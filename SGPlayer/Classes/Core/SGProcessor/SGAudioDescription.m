//
//  SGAudioDescription.m
//  SGPlayer
//
//  Created by Single on 2018/11/28.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioDescription.h"
#import "SGFrame+Internal.h"

@implementation SGAudioDescription

- (id)copyWithZone:(NSZone *)zone
{
    SGAudioDescription *obj = [[SGAudioDescription alloc] init];
    obj->_format = self->_format;
    obj->_sampleRate = self->_sampleRate;
    obj->_numberOfChannels = self->_numberOfChannels;
    obj->_channelLayout = self->_channelLayout;
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_format = AV_SAMPLE_FMT_FLTP;
        self->_sampleRate = 44100;
        self->_numberOfChannels = 2;
        self->_channelLayout = av_get_default_channel_layout(2);
    }
    return self;
}

@end
