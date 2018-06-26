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
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
}

- (void)fillWithTimebase:(CMTime)timebase packet:(SGFFPacket *)packet
{
    [super fillWithTimebase:timebase packet:packet];
    
    self.format = self.coreFrame->format;
    self.numberOfSamples = self.coreFrame->nb_samples;
    self.sampleRate = av_frame_get_sample_rate(self.coreFrame);
    self.numberOfChannels = av_frame_get_channels(self.coreFrame);
    self.channelLayout = av_frame_get_channel_layout(self.coreFrame);
    self.bestEffortTimestamp = av_frame_get_best_effort_timestamp(self.coreFrame);
    self.packetPosition = av_frame_get_pkt_pos(self.coreFrame);
    self.packetDuration = av_frame_get_pkt_duration(self.coreFrame);
    self.packetSize = av_frame_get_pkt_size(self.coreFrame);
    self.data = self.coreFrame->data;
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
}

@end
