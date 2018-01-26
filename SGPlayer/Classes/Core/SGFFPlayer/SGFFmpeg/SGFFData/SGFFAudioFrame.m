//
//  SGFFAudioFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioFrame.h"

@interface SGFFAudioFrame ()

@property (nonatomic, assign) AVFrame * coreFrame;

@end

@implementation SGFFAudioFrame

- (SGFFFrameType)type
{
    return SGFFFrameTypeAudio;
}

- (instancetype)init
{
    if (self = [super init])
    {
        NSLog(@"%s", __func__);
        self.coreFrame = av_frame_alloc();
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    if (self.coreFrame)
    {
        av_frame_free(&_coreFrame);
        self.coreFrame = nil;
    }
}

- (void)fillWithPacket:(AVPacket *)packet
{
    AVFrame * frame = self.coreFrame;
    if (frame)
    {
        self.format = frame->format;
        self.numberOfSamples = frame->nb_samples;
        self.sampleRate = av_frame_get_sample_rate(frame);
        self.numberOfChannels = av_frame_get_channels(frame);
        self.channelLayout = av_frame_get_channel_layout(frame);
        self.position = av_frame_get_best_effort_timestamp(frame);
        self.duration = av_frame_get_pkt_duration(frame);
        self.size = av_frame_get_pkt_size(frame);
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
    self.timebase = SGFFTimebaseIdentity();
    self.format = AV_SAMPLE_FMT_NONE;
    self.numberOfSamples = 0;
    self.sampleRate = 0;
    self.numberOfChannels = 0;
    self.channelLayout = 0;
    self.position = 0;
    self.duration = 0;
    self.size = 0;
    self.bestEffortTimestamp = 0;
    self.packetPosition = 0;
    self.packetDuration = 0;
    self.packetSize = 0;
    self.data = nil;
    if (self.coreFrame)
    {
        av_frame_unref(self.coreFrame);
    }
}

@end
