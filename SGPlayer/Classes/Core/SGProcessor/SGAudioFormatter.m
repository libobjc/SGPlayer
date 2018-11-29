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

- (BOOL)format:(SGAudioFrame *)original formatted:(SGAudioFrame **)formatted
{
    if (![original isKindOfClass:[SGAudioFrame class]]) {
        return NO;
    }
    if (self->_context.i_format != original.format ||
        self->_context.i_sample_rate != original.sampleRate ||
        self->_context.i_channels != original.numberOfChannels ||
        self->_context.i_channel_layout != original.channelLayout ||
        self->_context.o_format != self->_audioDescription.format ||
        self->_context.o_sample_rate != self->_audioDescription.sampleRate ||
        self->_context.o_channels != self->_audioDescription.numberOfChannels ||
        self->_context.o_channel_layout != self->_audioDescription.channelLayout) {
        self->_context = nil;
        SGSWResample *swrContext = [[SGSWResample alloc] init];
        swrContext.i_format = original.format;
        swrContext.i_sample_rate = original.sampleRate;
        swrContext.i_channels = original.numberOfChannels;
        swrContext.i_channel_layout = original.channelLayout;
        swrContext.o_format = self->_audioDescription.format;
        swrContext.o_sample_rate = self->_audioDescription.sampleRate;
        swrContext.o_channels = self->_audioDescription.numberOfChannels;
        swrContext.o_channel_layout = self->_audioDescription.channelLayout;
        if ([swrContext open]) {
            self->_context = swrContext;
        }
    }
    if (!self->_context) {
        return NO;
    }
    int nb_samples = [self->_context convert:original.data nb_samples:original.numberOfSamples];
    int nb_planar = av_sample_fmt_is_planar(self->_audioDescription.format) ? self->_audioDescription.numberOfChannels : 1;
    int linesize = av_get_bytes_per_sample(self->_audioDescription.format) * nb_samples;
    linesize *= av_sample_fmt_is_planar(self->_audioDescription.format) ? 1 : self->_audioDescription.numberOfChannels;
    SGAudioFrame *result = [[SGObjectPool sharedPool] objectWithClass:[SGAudioFrame class]];
    result.core->format = self->_audioDescription.format;
    result.core->channels = self->_audioDescription.numberOfChannels;
    result.core->channel_layout = self->_audioDescription.channelLayout;
    result.core->nb_samples = nb_samples;
    av_frame_copy_props(result.core, original.core);
    for (int i = 0; i < nb_planar; i++) {
        uint8_t *data = av_mallocz(linesize);
        [self->_context copy:data linesize:linesize planar:i];
        AVBufferRef *buffer = av_buffer_create(data, linesize, av_buffer_default_free, NULL, 0);
        result.core->buf[i] = buffer;
        result.core->data[i] = buffer->data;
        result.core->linesize[i] = buffer->size;
    }
    result.codecDescription = original.codecDescription;
    [result fill];
    *formatted = result;
    return YES;
}

@end
