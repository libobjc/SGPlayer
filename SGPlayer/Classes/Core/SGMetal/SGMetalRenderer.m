//
//  SGMetalRenderer.m
//  MetalTest
//
//  Created by Single on 2019/6/24.
//  Copyright © 2019 Single. All rights reserved.
//

#import "SGMetalRenderer.h"
#import "SGMetalTypes.h"

@interface SGMetalRenderer ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLBuffer> uniformBuffer;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) MTLRenderPassDescriptor *renderPassDescriptor;

@end

@implementation SGMetalRenderer

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super init]) {
        self.device = device;
        self.commandQueue = [self.device newCommandQueue];
        self.uniformBuffer = [self.device newBufferWithLength:sizeof(SGMetalUniforms) options:MTLResourceStorageModeShared];
        self.renderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
        self.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
        self.renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        self.renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    }
    return self;
}

- (id<MTLCommandBuffer>)drawModel:(SGMetalModel *)model
                         pipeline:(SGMetalRenderPipeline *)pipeline
                       projection:(SGMetalProjection *)projection
                    inputTextures:(NSArray<id<MTLTexture>> *)inputTextures
                    outputTexture:(id<MTLTexture>)outputTexture
{
    SGMetalUniforms *uniform = (SGMetalUniforms*)self.uniformBuffer.contents;
    uniform->modelViewProjection = projection.modelViewProjection;
    self.renderPassDescriptor.colorAttachments[0].texture = outputTexture;
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:self.renderPassDescriptor];
    [encoder setCullMode:MTLCullModeNone];
    [encoder setViewport:projection.viewport];
    [encoder setRenderPipelineState:pipeline.state];
    [encoder setVertexBuffer:model.vertexBuffer offset:0 atIndex:0];
    [encoder setVertexBuffer:self.uniformBuffer offset:0 atIndex:1];
    for (NSUInteger i = 0; i < inputTextures.count; i++) {
        [encoder setFragmentTexture:inputTextures[i] atIndex:i];
    }
    [encoder drawIndexedPrimitives:model.primitiveType
                        indexCount:model.indexCount
                         indexType:model.indexType
                       indexBuffer:model.indexBuffer
                 indexBufferOffset:0];
    [encoder endEncoding];
    return commandBuffer;
}

@end
