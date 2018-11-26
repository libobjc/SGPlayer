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
    BOOL _isPlanar;
    SInt32 _format;
    SInt32 _sampleRate;
    UInt64 _channelLayout;
    SInt32 _numberOfSsmples;
    SInt32 _numberOfChannels;
    SInt32 _linesize[SGFramePlaneCount];
    UInt8 *_data[SGFramePlaneCount];
}

@end

@implementation SGAudioFrame

- (SGMediaType)type
{
    return SGMediaTypeAudio;
}

#pragma mark - Setter & Getter

- (SInt32)format
{
    return self->_format;
}

- (BOOL)isPlanar
{
    return self->_isPlanar;
}

- (SInt32)sampleRate
{
    return self->_sampleRate;
}

- (SInt32)numberOfChannels
{
    return self->_numberOfChannels;
}

- (UInt64)channelLayout
{
    return self->_channelLayout;
}

- (SInt32)numberOfSamples
{
    return self->_numberOfSsmples;
}

- (SInt32 *)linesize
{
    return self->_linesize;
}

- (UInt8 **)data
{
    return self->_data;
}

#pragma mark - Item

- (void)clear
{
    [super clear];
    self->_isPlanar = NO;
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
    self->_isPlanar = av_sample_fmt_is_planar(frame->format);
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = frame->data[i];
        self->_linesize[i] = frame->linesize[i];
    }
}

@end
