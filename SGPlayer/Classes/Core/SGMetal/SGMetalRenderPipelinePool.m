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

#import "SGPLFTargets.h"
#if SGPLATFORM_TARGET_OS_IPHONE
#import "SGMetalShader_iOS.h"
#elif SGPLATFORM_TARGET_OS_TV
#import "SGMetalShader_tvOS.h"
#elif SGPLATFORM_TARGET_OS_MAC
#import "SGMetalShader_macOS.h"
#endif

@interface SGMetalRenderPipelinePool ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLLibrary> library;
@property (nonatomic, strong) SGMetalRenderPipeline *yuv;
@property (nonatomic, strong) SGMetalRenderPipeline *nv12;
@property (nonatomic, strong) SGMetalRenderPipeline *bgra;

@end

@implementation SGMetalRenderPipelinePool

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super init]) {
        self.device = device;
        self.library = [device newLibraryWithData:dispatch_data_create(metallib, sizeof(metallib), dispatch_get_global_queue(0, 0), ^{}) error:NULL];
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
        _yuv = [[SGMetalYUVRenderPipeline alloc] initWithDevice:self.device library:self.library];
    }
    return _yuv;
}

- (SGMetalRenderPipeline *)nv12
{
    if (_nv12 == nil) {
        _nv12 = [[SGMetalNV12RenderPipeline alloc] initWithDevice:self.device library:self.library];
    }
    return _nv12;
}

- (SGMetalRenderPipeline *)bgra
{
    if (_bgra == nil) {
        _bgra = [[SGMetalBGRARenderPipeline alloc] initWithDevice:self.device library:self.library];
    }
    return _bgra;
}

@end
