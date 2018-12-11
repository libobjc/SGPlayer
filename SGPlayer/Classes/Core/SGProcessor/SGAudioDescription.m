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

- (BOOL)isPlanar
{
    return av_sample_fmt_is_planar(self->_format);
}

- (int)bytesPerSample
{
    return av_get_bytes_per_sample(self->_format);
}

- (int)numberOfPlanes
{
    return av_sample_fmt_is_planar(self->_format) ? self->_numberOfChannels : 1;
}

- (int)linesize:(int)numberOfSamples
{
    int linesize = av_get_bytes_per_sample(self->_format) * numberOfSamples;
    linesize *= av_sample_fmt_is_planar(self->_format) ? 1 : self->_numberOfChannels;
    return linesize;
}

- (BOOL)isEqualToDescription:(SGAudioDescription *)description
{
    if (!description) {
        return NO;
    }
    return
    self->_format == description->_format &&
    self->_sampleRate == description->_sampleRate &&
    self->_numberOfChannels == description->_numberOfChannels &&
    self->_channelLayout == description->_channelLayout;
}

@end
