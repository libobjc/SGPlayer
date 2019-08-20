//
//  SGMetalBGRARenderPipeline.m
//  MetalTest
//
//  Created by Single on 2019/6/26.
//  Copyright © 2019 Single. All rights reserved.
//

#import "SGMetalBGRARenderPipeline.h"

@implementation SGMetalBGRARenderPipeline

- (instancetype)initWithDevice:(id<MTLDevice>)device library:(id<MTLLibrary>)library
{
    if (self = [super initWithDevice:device library:library]) {
        self.descriptor = [[MTLRenderPipelineDescriptor alloc] init];
        self.descriptor.vertexFunction = [self.library newFunctionWithName:@"vertexShader"];
        self.descriptor.fragmentFunction = [self.library newFunctionWithName:@"fragmentShaderBGRA"];
        self.descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        self.state = [self.device newRenderPipelineStateWithDescriptor:self.descriptor error:nil];
    }
    return self;
}

@end
