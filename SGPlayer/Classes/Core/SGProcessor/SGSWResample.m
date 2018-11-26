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
    SwrContext *_context;
    AVBufferRef *_buffer[SGFramePlaneCount];
}

@end

@implementation SGSWResample

- (void)dealloc
{
    if (self->_context) {
        swr_free(&_context);
        self->_context = nil;
    }
    for (int i = 0; i < SGFramePlaneCount; i++) {
        av_buffer_unref(&self->_buffer[i]);
        self->_buffer[i] = nil;
    }
}

- (BOOL)open
{
    if (self->_i_format == 0 ||
        self->_i_sample_rate == 0 ||
        self->_i_channels == 0 ||
        self->_i_channel_layout == 0 ||
        self->_o_format == 0 ||
        self->_o_sample_rate == 0 ||
        self->_o_channels == 0 ||
        self->_o_channel_layout == 0) {
        return NO;
    }
    self->_context = swr_alloc_set_opts(NULL,
                                        self->_o_channel_layout,
                                        self->_o_format,
                                        self->_o_sample_rate,
                                        self->_i_channel_layout,
                                        self.i_format,
                                        self->_i_sample_rate,
                                        0, NULL);
    if (swr_init(self->_context) < 0) {
        return NO;
    }
    return YES;
}

- (SInt32)convert:(UInt8 **)data nb_samples:(SInt32)nb_samples
{
    SInt32 o_nb_samples = swr_get_out_samples(self->_context, nb_samples);
    SInt32 o_nb_planar = av_sample_fmt_is_planar(self->_o_format) ? self->_o_channels : 1;
    SInt32 o_linesize = av_get_bytes_per_sample(self->_o_format) * o_nb_samples;
    o_linesize *= av_sample_fmt_is_planar(self->_o_format) ? 1 : self->_o_channels;
    UInt8 *o_data[SGFramePlaneCount] = {NULL};
    for (SInt32 i = 0; i < o_nb_planar; i++) {
        if (!self->_buffer[i] || self->_buffer[i]->size < o_linesize) {
            av_buffer_realloc(&self->_buffer[i], o_linesize);
        }
        o_data[i] = self->_buffer[i]->data;
    }
    return swr_convert(self->_context,
                       (UInt8 **)o_data,
                       o_nb_samples,
                       (const UInt8 **)data,
                       nb_samples);
}

- (SInt32)copy:(UInt8 *)data linesize:(SInt32)linesize planar:(SInt32)planar
{
    memcpy(data, self->_buffer[planar]->data, linesize);
    return linesize;
}

@end
