//
//  SGFFVideoAVFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFFVideoAVFrame.h"

@implementation SGFFVideoAVFrame

- (void)dealloc
{
    [self clear];
}

- (void)fillWithTimebase:(CMTime)timebase packet:(SGFFPacket *)packet
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
        int64_t timestamp = packet.corePacket->pts;
        if (packet.corePacket->pts == AV_NOPTS_VALUE) {
            timestamp = packet.corePacket->dts;
        }
        self.position = SGFFTimeMultiply(timebase, timestamp);
        self.duration = SGFFTimeMultiply(timebase, packet.corePacket->duration);
        self.size = packet.corePacket->size;
        self.bestEffortTimestamp = timestamp;
        self.packetPosition = packet.corePacket->pos;
        self.packetDuration = packet.corePacket->duration;
        self.packetSize = packet.corePacket->size;
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

- (void)clear
{
    self.corePixelBuffer = NULL;
}

@end
