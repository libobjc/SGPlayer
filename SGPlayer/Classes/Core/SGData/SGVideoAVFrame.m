//
//  SGVideoAVFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoAVFrame.h"

@interface SGVideoAVFrame ()

{
    uint8_t * _dataInternal[8];
    int _linesizeInternal[8];
}

@end

@implementation SGVideoAVFrame

- (void)clear
{
    [super clear];
    for (int i = 0; i < 8; i++)
    {
        _dataInternal[i] = NULL;
        _linesizeInternal[i] = 0;
    }
}

- (void)fillWithPacket:(SGPacket *)packet
{
    if (self.pixelBuffer)
    {
        OSType format = CVPixelBufferGetPixelFormatType(self.pixelBuffer);
        if (format == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
            self.format = SG_AV_PIX_FMT_NV12;
        } else if (format == kCVPixelFormatType_420YpCbCr8Planar) {
            self.format = SG_AV_PIX_FMT_YUV420P;
        } else if (format == kCVPixelFormatType_422YpCbCr8) {
            self.format = SG_AV_PIX_FMT_UYVY422;
        } else if (format == kCVPixelFormatType_32BGRA) {
            self.format = SG_AV_PIX_FMT_BGRA;
        } else {
            self.format = SG_AV_PIX_FMT_NONE;
        }
        if (CVPixelBufferIsPlanar(self.pixelBuffer)) {
            self.width = (int)CVPixelBufferGetWidthOfPlane(self.pixelBuffer, 0);
            self.height = (int)CVPixelBufferGetHeightOfPlane(self.pixelBuffer, 0);
        } else {
            self.width  = (int)CVPixelBufferGetWidth(self.pixelBuffer);
            self.height = (int)CVPixelBufferGetHeight(self.pixelBuffer);
        }
        CVPixelBufferLockBaseAddress(self.pixelBuffer, 0);
        int count = (int)CVPixelBufferGetPlaneCount(self.pixelBuffer);
        for (int i = 0; i < count; i++)
        {
            _dataInternal[i] = CVPixelBufferGetBaseAddressOfPlane(self.pixelBuffer, i);
            _linesizeInternal[i] = (int)CVPixelBufferGetBytesPerRowOfPlane(self.pixelBuffer, i);
        }
        CVPixelBufferUnlockBaseAddress(self.pixelBuffer, 0);
    }
    int64_t timestamp = packet.corePacket->pts;
    if (packet.corePacket->pts == AV_NOPTS_VALUE)
    {
        timestamp = packet.corePacket->dts;
    }
    self.timebase = packet.timebase;
    self.offset = packet.offset;
    self.scale = packet.scale;
    self.originalTimeStamp = packet.originalTimeStamp;
    self.originalDuration = packet.originalDuration;
    self.timeStamp = CMTimeAdd(self.offset, SGCMTimeMultiply(self.originalTimeStamp, self.scale));
    self.duration = packet.duration;
    self.decodeTimeStamp = packet.decodeTimeStamp;
    self.size = packet.corePacket->size;
    self.bestEffortTimestamp = timestamp;
    self.packetPosition = packet.corePacket->pos;
    self.packetDuration = packet.corePacket->duration;
    self.packetSize = packet.corePacket->size;
}

- (uint8_t **)data
{
    return _dataInternal;
}

- (int *)linesize
{
    return _linesizeInternal;
}

@end
