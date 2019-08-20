//
//  SGAudioDescriptor.m
//  SGPlayer
//
//  Created by Single on 2018/11/28.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioDescriptor.h"
#import "SGDescriptor+Internal.h"
#import "SGFFmpeg.h"

@implementation SGAudioDescriptor

- (id)copyWithZone:(NSZone *)zone
{
    SGAudioDescriptor *obj = [[SGAudioDescriptor alloc] init];
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

- (instancetype)initWithFrame:(AVFrame *)frame
{
    if (self = [super init]) {
        self->_format = frame->format;
        self->_sampleRate = frame->sample_rate;
        self->_numberOfChannels = frame->channels;
        self->_channelLayout = frame->channel_layout ? frame->channel_layout : av_get_default_channel_layout(frame->channels);
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

- (BOOL)isEqualToDescriptor:(SGAudioDescriptor *)descriptor
{
    if (!descriptor) {
        return NO;
    }
    return
    self->_format == descriptor->_format &&
    self->_sampleRate == descriptor->_sampleRate &&
    self->_numberOfChannels == descriptor->_numberOfChannels &&
    self->_channelLayout == descriptor->_channelLayout;
}

@end
