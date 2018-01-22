//
//  SGFFVideoFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoFrame.h"

@interface SGFFVideoFrame ()

@property (nonatomic, assign) SGFFVideoFrameDataType dataType;
@property (nonatomic, assign) AVFrame * coreFrame;
@property (nonatomic, assign) CVPixelBufferRef corePixelBuffer;

@end

@implementation SGFFVideoFrame

- (SGFFFrameType)type
{
    return SGFFFrameTypeVideo;
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
    if (self.coreFrame)
    {
        av_frame_free(&_coreFrame);
        self.coreFrame = nil;
    }
    if (self.corePixelBuffer)
    {
        CFRelease(self.corePixelBuffer);
        self.corePixelBuffer = nil;
    }
}

- (void)fill
{
    if (self.dataType == SGFFVideoFrameDataTypeAVFrame)
    {
        AVFrame * frame = self.coreFrame;
        if (frame)
        {
            self.format = frame->format;
            self.pictureType = frame->pict_type;
            self.colorRange = frame->color_range;
            self.colorPrimaries = frame->color_primaries;
            self.colorTransferCharacteristic = frame->color_trc;
            self.colorSpace = frame->colorspace;
            self.chromaLocation = frame->chroma_location;
            self.sampleAspectRatio = frame->sample_aspect_ratio;
            self.width = frame->width;
            self.height = frame->height;
            self.keyFrame = frame->key_frame;
            self.position = av_frame_get_best_effort_timestamp(frame);
            self.duration = av_frame_get_pkt_duration(frame);
            self.size = av_frame_get_pkt_size(frame);
            self.bestEffortTimestamp = av_frame_get_best_effort_timestamp(frame);
            self.packetPosition = av_frame_get_pkt_pos(frame);
            self.packetDuration = av_frame_get_pkt_duration(frame);
            self.packetSize = av_frame_get_pkt_size(frame);
            self.data = frame->data;
            self.linesize = frame->linesize;
        }
    }
}

- (void)clear
{
    [super clear];
    if (self.coreFrame)
    {
        av_frame_unref(self.coreFrame);
    }
    if (self.corePixelBuffer)
    {
        CFRelease(self.corePixelBuffer);
        self.corePixelBuffer = nil;
    }
}

- (void)updateDataType:(SGFFVideoFrameDataType)dataType
{
    self.dataType = dataType;
    if (self.dataType == SGFFVideoFrameDataTypeAVFrame)
    {
        if (!self.coreFrame)
        {
            self.coreFrame = av_frame_alloc();
        }
    }
}

- (void)updateCorePixelBuffer:(CVPixelBufferRef)corePixelBuffer
{
    if (self.corePixelBuffer)
    {
        CFRelease(self.corePixelBuffer);
    }
    self.corePixelBuffer = corePixelBuffer;
}

@end
