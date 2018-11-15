//
//  SGVideoFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGVideoFrame.h"
#import "SGFrame+Internal.h"
#import "SGSWScale.h"
#import "SGMapping.h"
#import "imgutils.h"

@implementation SGVideoFrame

- (SGMediaType)type
{
    return SGMediaTypeVideo;
}

- (instancetype)init
{
    if (self = [super init]) {
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
    
    _format = AV_PIX_FMT_NONE;
    _width = 0;
    _height = 0;
    _key_frame = 0;
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = nil;
        self->_linesize[i] = 0;
    }
    self->_pixelBuffer = nil;
}

- (void)setTimebase:(AVRational)timebase codecpar:(AVCodecParameters *)codecpar
{
    [super setTimebase:timebase codecpar:codecpar];
    
    _format = self.core->format;
    _width = self.core->width;
    _height = self.core->height;
    _key_frame = self.core->key_frame;
    if (self.format == AV_PIX_FMT_VIDEOTOOLBOX) {
        self->_pixelBuffer = (CVPixelBufferRef)(self.core->data[3]);
    }
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = self.core->data[i];
        self->_linesize[i] = self.core->linesize[i];
    }
}

- (SGPLFImage *)image
{
    if (self.width == 0 || self.height == 0) {
        return nil;
    }
    enum AVPixelFormat src_format = self.format;
    enum AVPixelFormat dst_format = AV_PIX_FMT_RGB24;
    const uint8_t * src_data[SGFramePlaneCount] = {nil};
    uint8_t * dst_data[SGFramePlaneCount] = {nil};
    int src_linesize[SGFramePlaneCount] = {0};
    int dst_linesize[SGFramePlaneCount] = {0};
    
    if (src_format == AV_PIX_FMT_VIDEOTOOLBOX) {
        if (!self->_pixelBuffer) {
            return nil;
        }
        OSType type = CVPixelBufferGetPixelFormatType(self->_pixelBuffer);
        src_format = SGPixelFormatAV2FF(type);
        
        CVReturn error = CVPixelBufferLockBaseAddress(self->_pixelBuffer, kCVPixelBufferLock_ReadOnly);
        if (error != kCVReturnSuccess) {
            return nil;
        }
        if (CVPixelBufferIsPlanar(self->_pixelBuffer)) {
            int planes = (int)CVPixelBufferGetPlaneCount(self->_pixelBuffer);
            for (int i = 0; i < planes; i++) {
                src_data[i] = CVPixelBufferGetBaseAddressOfPlane(self->_pixelBuffer, i);
                src_linesize[i] = (int)CVPixelBufferGetBytesPerRowOfPlane(self->_pixelBuffer, i);
            }
        } else {
            src_data[0] = CVPixelBufferGetBaseAddress(self->_pixelBuffer);
            src_linesize[0] = (int)CVPixelBufferGetBytesPerRow(self->_pixelBuffer);
        }
        CVPixelBufferUnlockBaseAddress(self->_pixelBuffer, kCVPixelBufferLock_ReadOnly);
    } else {
        for (int i = 0; i < SGFramePlaneCount; i++) {
            src_data[i] = self.core->data[i];
            src_linesize[i] = self.core->linesize[i];
        }
    }
    
    if (src_format == AV_PIX_FMT_NONE || !src_data[0] || !src_linesize[0]) {
        return nil;
    }
    
    SGSWScale * context = [[SGSWScale alloc] init];
    context.i_format = src_format;
    context.o_format = dst_format;
    context.width = self.width;
    context.height = self.height;
    if (![context open]) {
        return nil;
    }
    
    int result = av_image_alloc(dst_data, dst_linesize, self.width, self.height, dst_format, 1);
    if (result < 0) {
        return nil;
    }
    result = [context convert:src_data i_linesize:src_linesize o_data:dst_data o_linesize:dst_linesize];
    if (result < 0) {
        av_freep(dst_data);
        return nil;
    }
    SGPLFImage * image = SGPLFImageWithRGBData(dst_data[0], dst_linesize[0], self.width, self.height);
    av_freep(dst_data);
    return image;
}

@end
