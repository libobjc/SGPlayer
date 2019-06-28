//
//  SGSWResample.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/30.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSWResample.h"
#import "SGFFmpeg.h"
#import "SGFrame.h"

@interface SGSWResample ()

{
    AVBufferRef *_buffer[SGFramePlaneCount];
}

@property (nonatomic, readonly) SwrContext *context;

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
    if (!self->_inputDescriptor ||
        !self->_outputDescriptor) {
        return NO;
    }
    self->_context = swr_alloc_set_opts(NULL,
                                        self->_outputDescriptor.channelLayout,
                                        self->_outputDescriptor.format,
                                        self->_outputDescriptor.sampleRate,
                                        self->_inputDescriptor.channelLayout,
                                        self->_inputDescriptor.format,
                                        self->_inputDescriptor.sampleRate,
                                        0, NULL);
    if (swr_init(self->_context) < 0) {
        return NO;
    }
    return YES;
}

- (int)write:(uint8_t **)data nb_samples:(int)nb_samples
{
    int numberOfPlanes = self->_outputDescriptor.numberOfPlanes;
    int numberOfSamples = swr_get_out_samples(self->_context, nb_samples);
    int linesize = [self->_outputDescriptor linesize:numberOfSamples];
    uint8_t *o_data[SGFramePlaneCount] = {NULL};
    for (int i = 0; i < numberOfPlanes; i++) {
        if (!self->_buffer[i] || self->_buffer[i]->size < linesize) {
            av_buffer_realloc(&self->_buffer[i], linesize);
        }
        o_data[i] = self->_buffer[i]->data;
    }
    return swr_convert(self->_context,
                       (uint8_t **)o_data,
                       numberOfSamples,
                       (const uint8_t **)data,
                       nb_samples);
}

- (int)read:(uint8_t **)data nb_samples:(int)nb_samples
{
    int numberOfPlanes = self->_outputDescriptor.numberOfPlanes;
    int linesize = [self->_outputDescriptor linesize:nb_samples];
    for (int i = 0; i < numberOfPlanes; i++) {
        memcpy(data[i], self->_buffer[i]->data, linesize);
    }
    return nb_samples;
}

@end
