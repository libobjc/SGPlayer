//
//  SGVideoFFFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoFFFrame.h"

@implementation SGVideoFFFrame

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

- (void)fillWithPacket:(SGPacket *)packet
{
    self.timebase = packet.timebase;
    self.offset = packet.offset;
    self.scale = packet.scale;
    self.originalTimeStamp = SGTimeMultiply(packet.timebase, av_frame_get_best_effort_timestamp(self.coreFrame));
    self.originalDuration = SGTimeMultiply(packet.timebase, av_frame_get_pkt_duration(self.coreFrame));
    self.timeStamp = CMTimeAdd(self.offset, SGTimeMultiplyByTime(self.originalTimeStamp, self.scale));
    self.duration = SGTimeMultiplyByTime(self.originalDuration, self.scale);
    self.decodeTimeStamp = packet.decodeTimeStamp;
    self.size = av_frame_get_pkt_size(self.coreFrame);
    
    self.format = self.coreFrame->format;
    self.pictureType = self.coreFrame->pict_type;
    self.colorRange = self.coreFrame->color_range;
    self.colorPrimaries = self.coreFrame->color_primaries;
    self.colorTransferCharacteristic = self.coreFrame->color_trc;
    self.colorSpace = self.coreFrame->colorspace;
    self.chromaLocation = self.coreFrame->chroma_location;
    self.sampleAspectRatio = self.coreFrame->sample_aspect_ratio;
    self.width = self.coreFrame->width;
    self.height = self.coreFrame->height;
    self.keyFrame = self.coreFrame->key_frame;
    self.bestEffortTimestamp = av_frame_get_best_effort_timestamp(self.coreFrame);
    self.packetPosition = av_frame_get_pkt_pos(self.coreFrame);
    self.packetDuration = av_frame_get_pkt_duration(self.coreFrame);
    self.packetSize = av_frame_get_pkt_size(self.coreFrame);
    self.data = self.coreFrame->data;
    self.linesize = self.coreFrame->linesize;
}

- (void)clear
{
    [super clear];
    
    if (_coreFrame)
    {
        av_frame_unref(_coreFrame);
    }
}

@end
