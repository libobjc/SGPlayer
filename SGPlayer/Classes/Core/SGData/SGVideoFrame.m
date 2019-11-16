//
//  SGVideoFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGVideoFrame.h"
#import "SGFrame+Internal.h"
#import "SGDescriptor+Internal.h"
#import "SGObjectPool.h"
#import "SGMapping.h"
#import "SGSWScale.h"

@interface SGVideoFrame ()

{
    CVPixelBufferRef _pixelBuffer;
    int _linesize[SGFramePlaneCount];
    uint8_t *_data[SGFramePlaneCount];
}

@end

@implementation SGVideoFrame

+ (instancetype)frame
{
    static NSString *name = @"SGVideoFrame";
    return [[SGObjectPool sharedPool] objectWithClass:[self class] reuseName:name];
}

+ (instancetype)frameWithDescriptor:(SGVideoDescriptor *)descriptor
{
    SGVideoFrame *frame = [SGVideoFrame frame];
    uint8_t *data[SGFramePlaneCount] = {nil};
    int linesize[SGFramePlaneCount] = {0};
    int result = av_image_alloc(data,
                                linesize,
                                descriptor.width,
                                descriptor.height,
                                descriptor.format,
                                1);
    if (result < 0) {
        return frame;
    }
    frame.core->width = descriptor.width;
    frame.core->height = descriptor.height;
    frame.core->format = descriptor.format;
    frame.core->sample_aspect_ratio = (AVRational){
        descriptor.sampleAspectRatio.num,
        descriptor.sampleAspectRatio.den
    };
    for (int i = 0; i < descriptor.numberOfPlanes; i++) {
        AVBufferRef *buffer = av_buffer_create(data[i], linesize[i], NULL, NULL, 0);
        frame.core->buf[i] = buffer;
        frame.core->data[i] = buffer->data;
        frame.core->linesize[i] = buffer->size;
    }
    return frame;
}

#pragma mark - Setter & Getter

- (SGMediaType)type
{
    return SGMediaTypeVideo;
}

- (int *)linesize
{
    return self->_linesize;
}

- (uint8_t **)data
{
    return self->_data;
}

- (CVPixelBufferRef)pixelBuffer
{
    return self->_pixelBuffer;
}

- (SGPLFImage *)image
{
    SGRational presentationSize = self->_descriptor.presentationSize;
    if (presentationSize.num == 0 ||
        presentationSize.den == 0) {
        return nil;
    }
    SGVideoDescriptor *descriptor = [[SGVideoDescriptor alloc] init];
    descriptor.format = AV_PIX_FMT_RGB24;
    descriptor.width = presentationSize.num;
    descriptor.height = presentationSize.den;
    const uint8_t *src_data[SGFramePlaneCount] = {nil};
    uint8_t *dst_data[SGFramePlaneCount] = {nil};
    int src_linesize[SGFramePlaneCount] = {0};
    int dst_linesize[SGFramePlaneCount] = {0};
    if (self->_pixelBuffer) {
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
    if (!src_data[0] ||
        !src_linesize[0]) {
        return nil;
    }
    SGSWScale *context = [[SGSWScale alloc] init];
    context.inputDescriptor = self->_descriptor;
    context.outputDescriptor = descriptor;
    if (![context open]) {
        return nil;
    }
    int result = av_image_alloc(dst_data,
                                (int *)dst_linesize,
                                descriptor.width,
                                descriptor.height,
                                descriptor.format,
                                1);
    if (result < 0) {
        return nil;
    }
    result = [context convert:src_data
                inputLinesize:src_linesize
                   outputData:dst_data
               outputLinesize:dst_linesize];
    if (result < 0) {
        av_freep(dst_data);
        return nil;
    }
    SGPLFImage *image = SGPLFImageWithRGBData(dst_data[0],
                                              dst_linesize[0],
                                              descriptor.width,
                                              descriptor.height);
    av_freep(dst_data);
    return image;
}

#pragma mark - Data

- (void)clear
{
    [super clear];
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = nil;
        self->_linesize[i] = 0;
    }
    self->_pixelBuffer = nil;
    self->_descriptor = nil;
}

#pragma mark - Control

- (void)fill
{
    [super fill];
    [self fillData];
}

- (void)fillWithFrame:(SGFrame *)frame
{
    [super fillWithFrame:frame];
    SGVideoFrame *videoFrame = (SGVideoFrame *)frame;
    self->_pixelBuffer = videoFrame->_pixelBuffer;
    self->_descriptor = videoFrame->_descriptor.copy;
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = videoFrame->_data[i];
        self->_linesize[i] = videoFrame->_linesize[i];
    }
}

- (void)fillWithTimeStamp:(CMTime)timeStamp decodeTimeStamp:(CMTime)decodeTimeStamp duration:(CMTime)duration
{
    [super fillWithTimeStamp:timeStamp decodeTimeStamp:decodeTimeStamp duration:duration];
    [self fillData];
}

- (void)fillData
{
    AVFrame *frame = self.core;
    self->_descriptor = [[SGVideoDescriptor alloc] initWithFrame:frame];
    if (frame->format == AV_PIX_FMT_VIDEOTOOLBOX) {
        self->_pixelBuffer = (CVPixelBufferRef)(frame->data[3]);
        self->_descriptor.cv_format = CVPixelBufferGetPixelFormatType(self->_pixelBuffer);
    }
    for (int i = 0; i < SGFramePlaneCount; i++) {
        self->_data[i] = frame->data[i];
        self->_linesize[i] = frame->linesize[i];
    }
}

@end
