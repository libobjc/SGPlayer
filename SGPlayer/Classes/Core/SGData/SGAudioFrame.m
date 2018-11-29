//
//  SGAudioFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAudioFrame.h"
#import "SGFrame+Internal.h"

@interface SGAudioFrame ()

{
    int _format;
    int _planar;
    int _sampleRate;
    int _numberOfSsmples;
    int _numberOfChannels;
    uint64_t _channelLayout;
    int _linesize[SGFramePlaneCount];
    uint8_t *_data[SGFramePlaneCount];
}

@end

@implementation SGAudioFrame

- (SGMediaType)type
{
    return SGMediaTypeAudio;
}

#pragma mark - Setter & Getter

- (int)format
{
    return self->_format;
}

- (int)isPlanar
{
    return self->_planar;
}

- (int)sampleRate
{
    return self->_sampleRate;
}

- (int)numberOfChannels
{
    return self->_numberOfChannels;
}

- (uint64_t)channelLayout
{
    return self->_channelLayout;
}

- (int)numberOfSamples
{
    return self->_numberOfSsmples;
}

- (int *)linesize
{
    return self->_linesize;
}

- (uint8_t **)data
{
    return self->_data;
}

#pragma mark - Item

- (void)clear
{
    [super clear];
    self->_planar = 0;
    self->_sampleRate = 0;
    self->_channelLayout = 0;
    self->_numberOfSsmples = 0;
    self->_numberOfChannels = 0;
    self->_format = AV_SAMPLE_FMT_NONE;
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = nil;
        self->_linesize[i] = 0;
    }
}

#pragma mark - Control

- (void)fill
{
    [super fill];
    AVFrame *frame = self.core;
    self->_format = frame->format;
    self->_sampleRate = frame->sample_rate;
    self->_numberOfChannels = frame->channels;
    self->_numberOfSsmples = frame->nb_samples;
    self->_channelLayout = frame->channel_layout;
    self->_planar = av_sample_fmt_is_planar(frame->format);
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = frame->data[i];
        self->_linesize[i] = frame->linesize[i];
    }
}

@end
