//
//  SGAudioFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAudioFrame.h"
#import "SGFrame+Internal.h"
#import "SGDescription+Internal.h"
#import "SGObjectPool.h"

@interface SGAudioFrame ()

{
    int _linesize[SGFramePlaneCount];
    uint8_t *_data[SGFramePlaneCount];
}

@end

@implementation SGAudioFrame

+ (instancetype)audioFrameWithDescription:(SGAudioDescription *)description numberOfSamples:(int)numberOfSamples
{
    SGAudioFrame *frame = [[SGObjectPool sharedPool] objectWithClass:[SGAudioFrame class]];
    frame.core->format = description.format;
    frame.core->sample_rate = description.sampleRate;
    frame.core->channels = description.numberOfChannels;
    frame.core->channel_layout = description.channelLayout;
    frame.core->nb_samples = numberOfSamples;
    int linesize = [description linesize:numberOfSamples];
    int numberOfPlanes = description.numberOfPlanes;
    for (int i = 0; i < numberOfPlanes; i++) {
        uint8_t *data = av_mallocz(linesize);
        memset(data, 0, linesize);
        AVBufferRef *buffer = av_buffer_create(data, linesize, av_buffer_default_free, NULL, 0);
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
    self->_audioDescription = nil;
}

#pragma mark - Control

- (void)fill
{
    AVFrame *frame = self.core;
    AVRational timebase = self.codecDescription.timebase;
    SGCodecDescription *codecDescription = self.codecDescription;
    CMTime duration = CMTimeMake(frame->nb_samples, frame->sample_rate);
    CMTime timeStamp = CMTimeMake(frame->best_effort_timestamp * timebase.num, timebase.den);
    CMTime decodeTimeStamp = CMTimeMake(frame->pkt_dts * timebase.num, timebase.den);
    for (SGTimeLayout *obj in codecDescription.timeLayouts) {
        duration = [obj convertDuration:duration];
        timeStamp = [obj convertTimeStamp:timeStamp];
        decodeTimeStamp = [obj convertTimeStamp:decodeTimeStamp];
    }
    [self fillWithDuration:duration timeStamp:timeStamp decodeTimeStamp:decodeTimeStamp];
}

- (void)fillWithDuration:(CMTime)duration timeStamp:(CMTime)timeStamp decodeTimeStamp:(CMTime)decodeTimeStamp
{
    [super fillWithDuration:duration timeStamp:timeStamp decodeTimeStamp:decodeTimeStamp];
    AVFrame *frame = self.core;
    self->_numberOfSamples = frame->nb_samples;
    self->_audioDescription = [[SGAudioDescription alloc] initWithFrame:frame];
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = frame->data[i];
        self->_linesize[i] = frame->linesize[i];
    }
}

@end
