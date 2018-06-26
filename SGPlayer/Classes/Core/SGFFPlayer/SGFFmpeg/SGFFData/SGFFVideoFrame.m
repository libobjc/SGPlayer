//
//  SGFFVideoFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoFrame.h"
#import "SGFFTime.h"

@interface SGFFVideoFrame ()

@end

@implementation SGFFVideoFrame

- (SGMediaType)mediaType
{
    return SGMediaTypeVideo;
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
    
    self.format = AV_PIX_FMT_NONE;
    self.pictureType = AV_PICTURE_TYPE_NONE;
    self.colorRange = AVCOL_RANGE_UNSPECIFIED;
    self.colorPrimaries = AVCOL_PRI_RESERVED0;
    self.colorTransferCharacteristic = AVCOL_TRC_RESERVED0;
    self.colorSpace = AVCOL_SPC_RGB;
    self.chromaLocation = AVCHROMA_LOC_UNSPECIFIED;
    AVRational rational = {1, 1};
    self.sampleAspectRatio = rational;
    self.width = 0;
    self.height = 0;
    self.keyFrame = 0;
    self.bestEffortTimestamp = 0;
    self.packetPosition = 0;
    self.packetDuration = 0;
    self.packetSize = 0;
    self.data = NULL;
    self.linesize = NULL;
}

@end
