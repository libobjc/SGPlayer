//
//  SGAudioFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAudioFrame.h"
#import "SGFrame+Internal.h"
#import "SGDescriptor+Internal.h"
#import "SGObjectPool.h"

@interface SGAudioFrame ()

{
    int _linesize[SGFramePlaneCount];
    uint8_t *_data[SGFramePlaneCount];
}

@end

@implementation SGAudioFrame

+ (instancetype)frame
{
    static NSString *name = @"SGAudioFrame";
    return [[SGObjectPool sharedPool] objectWithClass:[self class] reuseName:name];
}

+ (instancetype)frameWithDescriptor:(SGAudioDescriptor *)descriptor numberOfSamples:(int)numberOfSamples
{
    SGAudioFrame *frame = [SGAudioFrame frame];
    frame.core->format = descriptor.format;
    frame.core->nb_samples = numberOfSamples;
    frame.core->sample_rate = descriptor.sampleRate;
    frame.core->channels = descriptor.numberOfChannels;
    frame.core->channel_layout = descriptor.channelLayout;
    int linesize = [descriptor linesize:numberOfSamples];
    for (int i = 0; i < descriptor.numberOfPlanes; i++) {
        uint8_t *data = av_mallocz(linesize);
        memset(data, 0, linesize);
        AVBufferRef *buffer = av_buffer_create(data, linesize, NULL, NULL, 0);
        frame.core->buf[i] = buffer;
        frame.core->data[i] = buffer->data;
        frame.core->linesize[i] = buffer->size;
    }
    return frame;
}

#pragma mark - Setter & Getter

- (SGMediaType)type
{
    return SGMediaTypeAudio;
}

- (int *)linesize
{
    return self->_linesize;
}

- (uint8_t **)data
{
    return self->_data;
}

#pragma mark - Data

- (void)clear
{
    [super clear];
    self->_numberOfSamples = 0;
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = nil;
        self->_linesize[i] = 0;
    }
    self->_descriptor = nil;
}

#pragma mark - Control

- (void)fill
{
    AVFrame *frame = self.core;
    AVRational timebase = self.codecDescriptor.timebase;
    SGCodecDescriptor *cd = self.codecDescriptor;
    CMTime duration = CMTimeMake(frame->nb_samples, frame->sample_rate);
    CMTime timeStamp = CMTimeMake(frame->best_effort_timestamp * timebase.num, timebase.den);
    CMTime decodeTimeStamp = CMTimeMake(frame->pkt_dts * timebase.num, timebase.den);
    duration = [cd convertDuration:duration];
    timeStamp = [cd convertTimeStamp:timeStamp];
    decodeTimeStamp = [cd convertTimeStamp:decodeTimeStamp];
    [self fillWithTimeStamp:timeStamp decodeTimeStamp:decodeTimeStamp duration:duration];
}

- (void)fillWithFrame:(SGFrame *)frame
{
    [super fillWithFrame:frame];
    SGAudioFrame *audioFrame = (SGAudioFrame *)frame;
    self->_numberOfSamples = audioFrame->_numberOfSamples;
    self->_descriptor = audioFrame->_descriptor.copy;
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = audioFrame->_data[i];
        self->_linesize[i] = audioFrame->_linesize[i];
    }
}

- (void)fillWithTimeStamp:(CMTime)timeStamp decodeTimeStamp:(CMTime)decodeTimeStamp duration:(CMTime)duration
{
    [super fillWithTimeStamp:timeStamp decodeTimeStamp:decodeTimeStamp duration:duration];
    AVFrame *frame = self.core;
    self->_numberOfSamples = frame->nb_samples;
    self->_descriptor = [[SGAudioDescriptor alloc] initWithFrame:frame];
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = frame->data[i];
        self->_linesize[i] = frame->linesize[i];
    }
}

@end
