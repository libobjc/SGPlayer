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
#import "channel_layout.h"

@interface SGAudioFrameFilter ()

@property (nonatomic, strong) SGSWResample * swrContext;

@end

@implementation SGAudioFrameFilter

- (instancetype)init
{
    if (self = [super init]) {
        self.format = AV_SAMPLE_FMT_FLTP;
        self.sample_rate = 44100;
        self.channels = 2;
        self.channel_layout = av_get_default_channel_layout(2);
    }
    return self;
}

- (__kindof SGFrame *)convert:(__kindof SGFrame *)frame
{
    if (![frame isKindOfClass:[SGAudioFrame class]]) {
        return [super convert:frame];
    }
    SGAudioFrame * audioFrame = frame;
    if (self.swrContext.i_format != audioFrame.format ||
        self.swrContext.i_sample_rate != audioFrame.sample_rate ||
        self.swrContext.i_channels != audioFrame.channels ||
        self.swrContext.i_channel_layout != audioFrame.channel_layout ||
        self.swrContext.o_format != self.format ||
        self.swrContext.o_sample_rate != self.sample_rate ||
        self.swrContext.o_channels != self.channels ||
        self.swrContext.o_channel_layout != self.channel_layout) {
        self.swrContext = nil;
        SGSWResample * swrContext = [[SGSWResample alloc] init];
        swrContext.i_format = audioFrame.format;
        swrContext.i_sample_rate = audioFrame.sample_rate;
        swrContext.i_channels = audioFrame.channels;
        swrContext.i_channel_layout = audioFrame.channel_layout;
        swrContext.o_format = self.format;
        swrContext.o_sample_rate = self.sample_rate;
        swrContext.o_channels = self.channels;
        swrContext.o_channel_layout = self.channel_layout;
        if ([swrContext open]) {
            self.swrContext = swrContext;
        }
    }
    if (!self.swrContext) {
        return [super convert:frame];
    }
    int nb_samples = [self.swrContext convert:audioFrame->_data nb_samples:audioFrame.nb_samples];
    int nb_planar = av_sample_fmt_is_planar(self.format) ? self.channels : 1;
    int linesize = av_get_bytes_per_sample(self.format) * nb_samples;
    linesize *= av_sample_fmt_is_planar(self.format) ? 1 : self.channels;
    SGAudioFrame * result = [[SGObjectPool sharePool] objectWithClass:[SGAudioFrame class]];
    result.core->format = self.format;
    result.core->channels = self.channels;
    result.core->channel_layout = self.channel_layout;
    result.core->nb_samples = nb_samples;
    av_frame_copy_props(result.core, audioFrame.core);
    for (int i = 0; i < nb_planar; i++) {
        uint8_t * data = av_mallocz(linesize);
        [self.swrContext copy:data linesize:linesize planar:i];
        AVBufferRef * buffer = av_buffer_create(data, linesize, av_buffer_default_free, NULL, 0);
        result.core->buf[i] = buffer;
        result.core->data[i] = buffer->data;
        result.core->linesize[i] = buffer->size;
    }
    [result configurateWithType:audioFrame.type timebase:audioFrame.timebase index:audioFrame.index];
    [result applyTimeTransforms:audioFrame.timeTransforms];
    [frame unlock];
    return result;
}

@end
