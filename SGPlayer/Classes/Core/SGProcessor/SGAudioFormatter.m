//
//  SGAudioFormatter.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/30.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioFormatter.h"
#import "SGFrame+Internal.h"
#import "SGAudioFrame.h"
#import "SGSWResample.h"

@interface SGAudioFormatter ()

{
    SGSWResample *_context;
}

@end

@implementation SGAudioFormatter

- (instancetype)initWithAudioDescription:(SGAudioDescription *)audioDescription
{
    if (self = [super init]) {
        self->_audioDescription = [audioDescription copy];
    }
    return self;
}

- (SGAudioFrame *)format:(SGAudioFrame *)frame
{
    if (![frame isKindOfClass:[SGAudioFrame class]]) {
        [frame unlock];
        return nil;
    }
    if (self->_context.i_format != frame.format ||
        self->_context.i_sample_rate != frame.sampleRate ||
        self->_context.i_channels != frame.numberOfChannels ||
        self->_context.i_channel_layout != frame.channelLayout ||
        self->_context.o_format != self->_audioDescription.format ||
        self->_context.o_sample_rate != self->_audioDescription.sampleRate ||
        self->_context.o_channels != self->_audioDescription.numberOfChannels ||
        self->_context.o_channel_layout != self->_audioDescription.channelLayout) {
        self->_context = nil;
        SGSWResample *context = [[SGSWResample alloc] init];
        context.i_format = frame.format;
        context.i_sample_rate = frame.sampleRate;
        context.i_channels = frame.numberOfChannels;
        context.i_channel_layout = frame.channelLayout;
        context.o_format = self->_audioDescription.format;
        context.o_sample_rate = self->_audioDescription.sampleRate;
        context.o_channels = self->_audioDescription.numberOfChannels;
        context.o_channel_layout = self->_audioDescription.channelLayout;
        if ([context open]) {
            self->_context = context;
        }
    }
    if (!self->_context) {
        [frame unlock];
        return nil;
    }
    
    int nb_samples = [self->_context convert:frame.data nb_samples:frame.numberOfSamples];
    int nb_planar = av_sample_fmt_is_planar(self->_audioDescription.format) ? self->_audioDescription.numberOfChannels : 1;
    int linesize = av_get_bytes_per_sample(self->_audioDescription.format) * nb_samples;
    linesize *= av_sample_fmt_is_planar(self->_audioDescription.format) ? 1 : self->_audioDescription.numberOfChannels;
    
    SGAudioFrame *ret = [[SGObjectPool sharedPool] objectWithClass:[SGAudioFrame class]];
    
    ret.core->format = self->_audioDescription.format;
    ret.core->sample_rate = self->_audioDescription.sampleRate;
    ret.core->channels = self->_audioDescription.numberOfChannels;
    ret.core->channel_layout = self->_audioDescription.channelLayout;
    ret.core->nb_samples = nb_samples;
    ret.core->pts = frame.core->pts;
    ret.core->pkt_dts = frame.core->pkt_dts;
    ret.core->pkt_size = frame.core->pkt_size;
    ret.core->pkt_duration = frame.core->pkt_duration;
    ret.core->best_effort_timestamp = frame.core->best_effort_timestamp;
    
    for (int i = 0; i < nb_planar; i++) {
        uint8_t *data = av_mallocz(linesize);
        [self->_context copy:data linesize:linesize planar:i];
        AVBufferRef *buffer = av_buffer_create(data, linesize, av_buffer_default_free, NULL, 0);
        ret.core->buf[i] = buffer;
        ret.core->data[i] = buffer->data;
        ret.core->linesize[i] = buffer->size;
    }
    
    ret.codecDescription = frame.codecDescription;
    [ret fill];
    [frame unlock];
    return ret;
}

@end
