//
//  SGMetalRenderPipelinePool.h
//  MetalTest
//
//  Created by Single on 2019/6/26.
//  Copyright © 2019 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGMetalRenderPipeline.h"
#import <CoreVideo/CoreVideo.h>

@interface SGMetalRenderPipelinePool : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (SGMetalRenderPipeline *)pipelineWithCVPixelFormat:(OSType)pixpelFormat;
- (SGMetalRenderPipeline *)pipelineWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
