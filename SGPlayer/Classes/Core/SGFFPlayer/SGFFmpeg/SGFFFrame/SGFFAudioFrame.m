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

- (void)fill
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

@end
