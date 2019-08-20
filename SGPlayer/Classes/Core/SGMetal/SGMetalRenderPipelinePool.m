//
//  SGMetalRenderPipelinePool.m
//  MetalTest
//
//  Created by Single on 2019/6/26.
//  Copyright © 2019 Single. All rights reserved.
//

#import "SGMetalRenderPipelinePool.h"
#import "SGMetalYUVRenderPipeline.h"
#import "SGMetalNV12RenderPipeline.h"
#import "SGMetalBGRARenderPipeline.h"

@interface SGMetalRenderPipelinePool ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) SGMetalRenderPipeline *yuv;
@property (nonatomic, strong) SGMetalRenderPipeline *nv12;
@property (nonatomic, strong) SGMetalRenderPipeline *bgra;

@end

@implementation SGMetalRenderPipelinePool

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super init]) {
        self.device = device;
    }
    return self;
}

- (SGMetalRenderPipeline *)pipelineWithCVPixelFormat:(OSType)pixpelFormat
{
    if (pixpelFormat == kCVPixelFormatType_420YpCbCr8Planar) {
        return self.yuv;
    } else if (pixpelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
        return self.nv12;
    } else if (pixpelFormat == kCVPixelFormatType_32BGRA) {
        return self.bgra;
    }
    return nil;
}

- (SGMetalRenderPipeline *)pipelineWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    return [self pipelineWithCVPixelFormat:CVPixelBufferGetPixelFormatType(pixelBuffer)];
}

- (SGMetalRenderPipeline *)yuv
{
    if (_yuv == nil) {
        _yuv = [[SGMetalYUVRenderPipeline alloc] initWithDevice:self.device];
    }
    return _yuv;
}

- (SGMetalRenderPipeline *)nv12
{
    if (_nv12 == nil) {
        _nv12 = [[SGMetalNV12RenderPipeline alloc] initWithDevice:self.device];
    }
    return _nv12;
}

- (SGMetalRenderPipeline *)bgra
{
    if (_bgra == nil) {
        _bgra = [[SGMetalBGRARenderPipeline alloc] initWithDevice:self.device];
    }
    return _bgra;
}

@end
