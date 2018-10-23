//
//  SGAudioFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAudioFrame.h"
#import "SGFrame+Private.h"
#import "SGFFDefinesMapping.h"

@implementation SGAudioFrame

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

- (void)clear
{
    [super clear];
    
    self.format = SG_AV_SAMPLE_FMT_NONE;
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

- (void)configurateWithStream:(SGStream *)stream
{
    [super configurateWithStream:stream];
    
    self.format = SGDMSampleFormatFF2SG(self.core->format);
    self.numberOfSamples = self.core->nb_samples;
    self.sampleRate = self.core->sample_rate;
    self.numberOfChannels = self.core->channels;
    self.channelLayout = self.core->channel_layout;
    self.bestEffortTimestamp = self.core->best_effort_timestamp;
    self.packetPosition = self.core->pkt_pos;
    self.packetDuration = self.core->pkt_duration;
    self.packetSize = self.core->pkt_size;
    self.data = self.core->data;
    self.linesize = self.core->linesize;
}

@end
