//
//  SGMetalYUVRenderPipeline.m
//  MetalTest
//
//  Created by Single on 2019/6/26.
//  Copyright © 2019 Single. All rights reserved.
//

#import "SGMetalYUVRenderPipeline.h"

@implementation SGMetalYUVRenderPipeline

- (instancetype)initWithDevice:(id<MTLDevice>)device library:(id<MTLLibrary>)library
{
    if (self = [super initWithDevice:device library:library]) {
		
		NSError *error = nil;
		
        self.descriptor = [[MTLRenderPipelineDescriptor alloc] init];
        self.descriptor.vertexFunction = [self.library newFunctionWithName:@"vertexShader" constantValues:[MTLFunctionConstantValues new] error:&error];
		
		if (error)
			NSLog(@"ERROR: %@", error.localizedDescription);
		
        self.descriptor.fragmentFunction = [self.library newFunctionWithName:@"fragmentShaderYUV" constantValues:[MTLFunctionConstantValues new] error:&error];
		
		if (error)
			NSLog(@"ERROR: %@", error.localizedDescription);
		
		self.descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        self.state = [self.device newRenderPipelineStateWithDescriptor:self.descriptor error:&error];
		
		if (error)
			NSLog(@"ERROR: %@", error.localizedDescription);
		
    }
    return self;
}

@end


