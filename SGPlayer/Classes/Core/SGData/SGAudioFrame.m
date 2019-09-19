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

+ (instancetype)audioFrameWithDescriptor:(SGAudioDescriptor *)descriptor numberOfSamples:(int)numberOfSamples
{
    SGAudioFrame *frame = [[SGObjectPool sharedPool] objectWithClass:[SGAudioFrame class] reuseName:[SGAudioFrame commonReuseName]];
    frame.core->format = descriptor.format;
    frame.core->sample_rate = descriptor.sampleRate;
    frame.core->channels = descriptor.numberOfChannels;
    frame.core->channel_layout = descriptor.channelLayout;
    frame.core->nb_samples = numberOfSamples;
    int linesize = [descriptor linesize:numberOfSamples];
    int numberOfPlanes = descriptor.numberOfPlanes;
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

+ (NSString *)commonReuseName
{
    static NSString *ret = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ret = NSStringFromClass(self.class);
    });
    return ret;
}

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
