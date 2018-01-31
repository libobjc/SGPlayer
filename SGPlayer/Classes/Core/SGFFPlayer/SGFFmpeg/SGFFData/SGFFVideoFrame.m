//
//  SGFFVideoFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoFrame.h"
#import <AVFoundation/AVFoundation.h>

@interface SGFFVideoFrame ()

@property (nonatomic, assign) AVFrame * coreFrame;

SGFFObjectPoolItemInterface

@end

@implementation SGFFVideoFrame

SGFFObjectPoolItemLockingImplementation
SGFFFramePointerCoversionImplementation

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
        CVPixelBufferRelease(self.corePixelBuffer);
        self.corePixelBuffer = nil;
    }
}

- (void)fill
{
    [self fillWithPacket:NULL];
}

- (void)fillWithPacket:(AVPacket *)packet
{
    switch (self.dataType)
    {
        case SGFFVideoFrameDataTypeUnknown:
            break;
        case SGFFVideoFrameDataTypeAVFrame:
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
            break;
        case SGFFVideoFrameDataTypeCVPixelBuffer:
        {
            CVPixelBufferRef pixelBuffer = self.corePixelBuffer;
            if (pixelBuffer)
            {
                OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);
                if (format == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
                    self.format = AV_PIX_FMT_NV12;
                } else if (format == kCVPixelFormatType_420YpCbCr8Planar) {
                    self.format = AV_PIX_FMT_YUV420P;
                } else if (format == kCVPixelFormatType_422YpCbCr8) {
                    self.format = AV_PIX_FMT_UYVY422;
                } else if (format == kCVPixelFormatType_32BGRA) {
                    self.format = AV_PIX_FMT_BGRA;
                } else {
                    self.format = AV_PIX_FMT_NONE;
                }
                if (CVPixelBufferIsPlanar(pixelBuffer)) {
                    self.width = (int)CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
                    self.height = (int)CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
                } else {
                    self.width  = (int)CVPixelBufferGetWidth(pixelBuffer);
                    self.height = (int)CVPixelBufferGetHeight(pixelBuffer);
                }
            }
            if (packet)
            {
                if (packet->pts != AV_NOPTS_VALUE) {
                    self.position = packet->pts;
                } else {
                    self.position = packet->dts;
                }
                self.duration = packet->duration;
                self.size = packet->size;
                self.bestEffortTimestamp = self.position;
                self.packetPosition = packet->pos;
                self.packetDuration = packet->duration;
                self.packetSize = packet->size;
            }
        }
            break;
    }
}

- (void)clear
{
    if (_coreFrame)
    {
        av_frame_unref(_coreFrame);
    }
    self.corePixelBuffer = NULL;
    self.dataType = SGFFVideoFrameDataTypeUnknown;
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
    self.position = 0;
    self.duration = 0;
    self.size = 0;
    self.bestEffortTimestamp = 0;
    self.packetPosition = 0;
    self.packetDuration = 0;
    self.packetSize = 0;
    self.data = NULL;
    self.linesize = NULL;
}

- (void)setDataType:(SGFFVideoFrameDataType)dataType
{
    _dataType = dataType;
    if (_dataType == SGFFVideoFrameDataTypeAVFrame && !_coreFrame)
    {
        _coreFrame = av_frame_alloc();
    }
}

- (void)setCorePixelBuffer:(CVPixelBufferRef)corePixelBuffer
{
    if (corePixelBuffer)
    {
        CVPixelBufferRetain(corePixelBuffer);
    }
    if (_corePixelBuffer)
    {
        CVPixelBufferRelease(_corePixelBuffer);
    }
    _corePixelBuffer = corePixelBuffer;
}

@end
