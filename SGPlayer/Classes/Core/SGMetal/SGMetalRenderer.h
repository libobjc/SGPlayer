//
//  SGMetalRenderer.h
//  MetalTest
//
//  Created by Single on 2019/6/24.
//  Copyright © 2019 Single. All rights reserved.
//

#import <simd/simd.h>
#import <Metal/Metal.h>
#import "SGMetalModel.h"
#import "SGMetalRenderPipeline.h"

@interface SGMetalRenderer : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (id<MTLCommandBuffer>)drawModel:(SGMetalModel *)model
                        viewports:(MTLViewport[])viewports
                         uniforms:(NSArray<id<MTLBuffer>> *)uniforms
                         pipeline:(SGMetalRenderPipeline *)pipeline
                    inputTextures:(NSArray<id<MTLTexture>> *)inputTextures
                    outputTexture:(id<MTLTexture>)outputTexture;

@end
