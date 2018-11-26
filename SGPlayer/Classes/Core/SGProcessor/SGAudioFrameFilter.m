//
//  SGAudioFrameFilter.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/30.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioFrameFilter.h"
#import "SGFrame+Internal.h"
#import "SGAudioFrame.h"
#import "SGSWResample.h"

@interface SGAudioFrameFilter ()

{
    SGSWResample * _swrContext;
}

@end

@implementation SGAudioFrameFilter

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

- (__kindof SGFrame *)convert:(__kindof SGFrame *)frame
{
    if (![frame isKindOfClass:[SGAudioFrame class]]) {
        return [super convert:frame];
    }
    SGAudioFrame * audioFrame = frame;
    if (self->_swrContext.i_format != audioFrame.format ||
        self->_swrContext.i_sample_rate != audioFrame.sampleRate ||
        self->_swrContext.i_channels != audioFrame.numberOfChannels ||
        self->_swrContext.i_channel_layout != audioFrame.channelLayout ||
        self->_swrContext.o_format != self->_format ||
        self->_swrContext.o_sample_rate != self->_sampleRate ||
        self->_swrContext.o_channels != self->_numberOfChannels ||
        self->_swrContext.o_channel_layout != self->_channelLayout) {
        self->_swrContext = nil;
        SGSWResample * swrContext = [[SGSWResample alloc] init];
        swrContext.i_format = audioFrame.format;
        swrContext.i_sample_rate = audioFrame.sampleRate;
        swrContext.i_channels = audioFrame.numberOfChannels;
        swrContext.i_channel_layout = audioFrame.channelLayout;
        swrContext.o_format = self->_format;
        swrContext.o_sample_rate = self->_sampleRate;
        swrContext.o_channels = self->_numberOfChannels;
        swrContext.o_channel_layout = self->_channelLayout;
        if ([swrContext open]) {
            self->_swrContext = swrContext;
        }
    }
    if (!self->_swrContext) {
        return [super convert:frame];
    }
    int nb_samples = [self->_swrContext convert:audioFrame.data nb_samples:audioFrame.numberOfSamples];
    int nb_planar = av_sample_fmt_is_planar(self->_format) ? self->_numberOfChannels : 1;
    int linesize = av_get_bytes_per_sample(self->_format) * nb_samples;
    linesize *= av_sample_fmt_is_planar(self->_format) ? 1 : self->_numberOfChannels;
    SGAudioFrame * result = [[SGObjectPool sharedPool] objectWithClass:[SGAudioFrame class]];
    result.core->format = self->_format;
    result.core->channels = self->_numberOfChannels;
    result.core->channel_layout = self->_channelLayout;
    result.core->nb_samples = nb_samples;
    av_frame_copy_props(result.core, audioFrame.core);
    for (int i = 0; i < nb_planar; i++) {
        uint8_t * data = av_mallocz(linesize);
        [self->_swrContext copy:data linesize:linesize planar:i];
        AVBufferRef * buffer = av_buffer_create(data, linesize, av_buffer_default_free, NULL, 0);
        result.core->buf[i] = buffer;
        result.core->data[i] = buffer->data;
        result.core->linesize[i] = buffer->size;
    }
    result.codecDescription = audioFrame.codecDescription;
    [result fill];
    [frame unlock];
    return result;
}

@end
