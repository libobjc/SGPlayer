//
//  SGVideoFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGVideoFrame.h"
#import "SGFrame+Internal.h"
#import "SGMapping.h"
#import "SGSWScale.h"
#import "imgutils.h"

@interface SGVideoFrame ()

{
     BOOL _isKey;
    SInt32 _format;
    SInt32 _width;
    SInt32 _height;
    SInt32 _linesize[SGFramePlaneCount];
    UInt8 *_data[SGFramePlaneCount];
    CVPixelBufferRef _pixelBuffer;
}

@end

@implementation SGVideoFrame

- (SGMediaType)type
{
    return SGMediaTypeVideo;
}

#pragma mark - Setter & Getter

- (SInt32)format
{
    return self->_format;
}

- (BOOL)isKey
{
    return self->_isKey;
}

- (SInt32)width
{
    return self->_width;
}

- (SInt32)height
{
    return self->_height;
}

- (SInt32 *)linesize
{
    return self->_linesize;
}

- (UInt8 **)data
{
    return self->_data;
}

- (CVPixelBufferRef)pixelBuffer
{
    return self->_pixelBuffer;
}

#pragma mark - Item

- (void)clear
{
    [super clear];
    self->_width = 0;
    self->_height = 0;
    self->_isKey = NO;
    self->_format = AV_PIX_FMT_NONE;
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = nil;
        self->_linesize[i] = 0;
    }
    self->_pixelBuffer = nil;
}

#pragma mark - Control

- (void)fill
{
    [super fill];
    AVFrame *frame = self.core;
    self->_width = frame->width;
    self->_height = frame->height;
    self->_format = frame->format;
    self->_isKey = frame->key_frame;
    if (self->_format == AV_PIX_FMT_VIDEOTOOLBOX) {
        self->_pixelBuffer = (CVPixelBufferRef)(frame->data[3]);
    }
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = frame->data[i];
        self->_linesize[i] = frame->linesize[i];
    }
}

- (SGPLFImage *)image
{
    if (self->_width == 0 || self->_height == 0) {
        return nil;
    }
    enum AVPixelFormat src_format = self->_format;
    enum AVPixelFormat dst_format = AV_PIX_FMT_RGB24;
    const uint8_t *src_data[SGFramePlaneCount] = {nil};
    uint8_t *dst_data[SGFramePlaneCount] = {nil};
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
            AVFrame *frame = self.core;
            src_data[i] = frame->data[i];
            src_linesize[i] = frame->linesize[i];
        }
    }
    
    if (src_format == AV_PIX_FMT_NONE || !src_data[0] || !src_linesize[0]) {
        return nil;
    }
    
    SGSWScale *context = [[SGSWScale alloc] init];
    context.i_format = src_format;
    context.o_format = dst_format;
    context.width = self->_width;
    context.height = self->_height;
    if (![context open]) {
        return nil;
    }
    
    int result = av_image_alloc(dst_data, dst_linesize, self->_width, self->_height, dst_format, 1);
    if (result < 0) {
        return nil;
    }
    result = [context convert:src_data i_linesize:src_linesize o_data:dst_data o_linesize:dst_linesize];
    if (result < 0) {
        av_freep(dst_data);
        return nil;
    }
    SGPLFImage *image = SGPLFImageWithRGBData(dst_data[0], dst_linesize[0], self->_width, self->_height);
    av_freep(dst_data);
    return image;
}

@end
