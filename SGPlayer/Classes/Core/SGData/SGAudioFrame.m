//
//  SGAudioFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAudioFrame.h"
#import "SGFrame+Internal.h"

@implementation SGAudioFrame

- (SGMediaType)type
{
    return SGMediaTypeAudio;
}

- (void)clear
{
    [super clear];
    self->_format = AV_SAMPLE_FMT_NONE;
    self->_is_planar = 0;
    self->_nb_samples = 0;
    self->_sample_rate = 0;
    self->_channels = 0;
    self->_channel_layout = 0;
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = nil;
        self->_linesize[i] = 0;
    }
}

- (void)fill
{
    [super fill];
    AVFrame * frame = self.core;
    self->_format = frame->format;
    self->_is_planar = av_sample_fmt_is_planar(frame->format);
    self->_nb_samples = frame->nb_samples;
    self->_sample_rate = frame->sample_rate;
    self->_channels = frame->channels;
    self->_channel_layout = frame->channel_layout;
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = frame->data[i];
        self->_linesize[i] = frame->linesize[i];
    }
}

@end
