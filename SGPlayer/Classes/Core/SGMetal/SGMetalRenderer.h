//
//  SGMetalRenderer.h
//  MetalTest
//
//  Created by Single on 2019/6/24.
//  Copyright © 2019 Single. All rights reserved.
//

#import <Metal/Metal.h>
#import "SGMetalModel.h"
#import "SGMetalProjection.h"
#import "SGMetalRenderPipeline.h"

@interface SGMetalRenderer : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (id<MTLCommandBuffer>)drawModel:(SGMetalModel *)model
                         pipeline:(SGMetalRenderPipeline *)pipeline
                       projection:(SGMetalProjection *)projection
                    inputTextures:(NSArray<id<MTLTexture>> *)inputTextures
                    outputTexture:(id<MTLTexture>)outputTexture;

@end
