//
//  SGAudioFFFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioFFFrame.h"
#import "SGFFDefinesMapping.h"

@implementation SGAudioFFFrame

@synthesize coreFrame = _coreFrame;

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

- (void)clear
{
    [super clear];
    if (_coreFrame)
    {
        av_frame_unref(_coreFrame);
    }
}

- (void)fillWithPacket:(SGPacket *)packet
{
    self.timebase = packet.timebase;
    self.scale = packet.scale;
    self.startTime = packet.startTime;
    self.timeRange = packet.timeRange;
    self.originalTimeStamp = SGCMTimeMakeWithTimebase(self.coreFrame->best_effort_timestamp, packet.timebase);
    self.originalDecodeTimeStamp = SGCMTimeMakeWithTimebase(self.coreFrame->pkt_dts, packet.timebase);
    self.originalDuration = SGCMTimeMakeWithTimebase(self.coreFrame->pkt_duration, packet.timebase);
    CMTime offset = CMTimeSubtract(self.startTime, packet.timeRange.start);
    self.timeStamp = CMTimeAdd(offset, SGCMTimeMultiply(self.originalTimeStamp, self.scale));
    self.decodeTimeStamp = CMTimeAdd(offset, SGCMTimeMultiply(self.originalDecodeTimeStamp, self.scale));
    self.duration = SGCMTimeMultiply(self.originalDuration, self.scale);
    self.size = self.coreFrame->pkt_size;
    
    self.format = SGDMSampleFormatFF2SG(self.coreFrame->format);
    self.numberOfSamples = self.coreFrame->nb_samples;
    self.sampleRate = self.coreFrame->sample_rate;
    self.numberOfChannels = self.coreFrame->channels;
    self.channelLayout = self.coreFrame->channel_layout;
    self.bestEffortTimestamp = self.coreFrame->best_effort_timestamp;
    self.packetPosition = self.coreFrame->pkt_pos;
    self.packetDuration = self.coreFrame->pkt_duration;
    self.packetSize = self.coreFrame->pkt_size;
    self.data = self.coreFrame->data;
    self.linesize = self.coreFrame->linesize;
}

@end
