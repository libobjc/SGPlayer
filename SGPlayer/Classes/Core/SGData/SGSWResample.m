//
//  SGSWResample.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/30.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSWResample.h"
#import "swresample.h"
#import "SGFrame.h"

@interface SGSWResample ()

{
    AVBufferRef * _buffer[SGFramePlaneCount];
}

@property (nonatomic, assign) SwrContext * swrContext;

@end

@implementation SGSWResample

- (void)dealloc
{
    if (self.swrContext) {
        swr_free(&_swrContext);
        self.swrContext = nil;
    }
    for (int i = 0; i < SGFramePlaneCount; i++) {
        av_buffer_unref(&_buffer[i]);
        _buffer[i] = nil;
    }
}

- (BOOL)open
{
    if (self.i_format == 0 ||
        self.i_sample_rate == 0 ||
        self.i_channels == 0 ||
        self.i_channel_layout == 0 ||
        self.o_format == 0 ||
        self.o_sample_rate == 0 ||
        self.o_channels == 0 ||
        self.o_channel_layout == 0)
    {
        return NO;
    }
    self.swrContext = swr_alloc_set_opts(NULL,
                                         self.o_channel_layout,
                                         self.o_format,
                                         self.o_sample_rate,
                                         self.i_channel_layout,
                                         self.i_format,
                                         self.i_sample_rate,
                                         0, NULL);
    if (swr_init(self.swrContext) < 0)
    {
        return NO;
    }
    return YES;
}

- (int)convert:(uint8_t **)data nb_samples:(int)nb_samples
{
    int o_nb_samples = swr_get_out_samples(self.swrContext, nb_samples);
    int o_nb_planar = av_sample_fmt_is_planar(self.o_format) ? self.o_channels : 1;
    int o_linesize = av_get_bytes_per_sample(self.o_format) * o_nb_samples;
    o_linesize *= av_sample_fmt_is_planar(self.o_format) ? 1 : self.o_channels;
    uint8_t * o_data[SGFramePlaneCount] = {NULL};
    for (int i = 0; i < o_nb_planar; i++) {
        if (!_buffer[i] || _buffer[i]->size < o_linesize) {
            av_buffer_realloc(&_buffer[i], o_linesize);
        }
        o_data[i] = _buffer[i]->data;
    }
    return swr_convert(self.swrContext, (uint8_t **)o_data, o_nb_samples, (const uint8_t **)data, nb_samples);
}

- (int)copy:(uint8_t *)data linesize:(int)linesize planar:(int)planar
{
    memcpy(data, _buffer[planar]->data, linesize);
    return linesize;
}

@end
