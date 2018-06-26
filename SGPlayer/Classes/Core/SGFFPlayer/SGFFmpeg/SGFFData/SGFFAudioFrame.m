//
//  SGFFAudioFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioFrame.h"
#import "SGFFTime.h"

@interface SGFFAudioFrame ()

@property (nonatomic, assign, readonly) AVFrame * coreFrame;

@end

@implementation SGFFAudioFrame

- (SGMediaType)mediaType
{
    return SGMediaTypeAudio;
}

- (instancetype)init
{
    if (self = [super init])
    {
        NSLog(@"%s", __func__);
        _coreFrame = av_frame_alloc();
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    if (_coreFrame)
    {
        av_frame_free(&_coreFrame);
        _coreFrame = NULL;
    }
}

- (void)fillWithTimebase:(CMTime)timebase
{
    [self fillWithTimebase:timebase packet:NULL];
}

- (void)fillWithTimebase:(CMTime)timebase packet:(SGFFPacket *)packet
{
    AVFrame * frame = _coreFrame;
    if (frame)
    {
        self.position = SGFFTimeMultiply(timebase, av_frame_get_best_effort_timestamp(frame));
        self.duration = SGFFTimeMultiply(timebase, av_frame_get_pkt_duration(frame));
        self.size = av_frame_get_pkt_size(frame);
        
        self.format = frame->format;
        self.numberOfSamples = frame->nb_samples;
        self.sampleRate = av_frame_get_sample_rate(frame);
        self.numberOfChannels = av_frame_get_channels(frame);
        self.channelLayout = av_frame_get_channel_layout(frame);
        self.bestEffortTimestamp = av_frame_get_best_effort_timestamp(frame);
        self.packetPosition = av_frame_get_pkt_pos(frame);
        self.packetDuration = av_frame_get_pkt_duration(frame);
        self.packetSize = av_frame_get_pkt_size(frame);
        self.data = frame->data;
    }
}

- (void)clear
{
    [super clear];

    self.format = AV_SAMPLE_FMT_NONE;
    self.numberOfSamples = 0;
    self.sampleRate = 0;
    self.numberOfChannels = 0;
    self.channelLayout = 0;
    self.bestEffortTimestamp = 0;
    self.packetPosition = 0;
    self.packetDuration = 0;
    self.packetSize = 0;
    self.data = nil;
    if (_coreFrame)
    {
        av_frame_unref(_coreFrame);
    }
}

@end
