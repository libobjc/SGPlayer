//
//  SGMetalPlaneModel.m
//  MetalTest
//
//  Created by Single on 2019/6/25.
//  Copyright © 2019 Single. All rights reserved.
//

#import "SGMetalPlaneModel.h"
#import "SGMetalTypes.h"

@implementation SGMetalPlaneModel

static const UInt32 indices[] = {
    0, 1, 3, 0, 3, 2,
};

static const SGMetalVertex vertices[] = {
    { { -1.0,  -1.0,  0.0,  1.0 }, { 0.0, 1.0 } },
    { { -1.0,   1.0,  0.0,  1.0 }, { 0.0, 0.0 } },
    { {  1.0,  -1.0,  0.0,  1.0 }, { 1.0, 1.0 } },
    { {  1.0,   1.0,  0.0,  1.0 }, { 1.0, 0.0 } },
};

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super initWithDevice:device]) {
        self.indexCount = 6;
        self.indexType = MTLIndexTypeUInt32;
        self.primitiveType = MTLPrimitiveTypeTriangle;
        self.indexBuffer = [self.device newBufferWithBytes:indices length:sizeof(indices) options:MTLResourceStorageModeShared];
        self.vertexBuffer = [self.device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceStorageModeShared];
    }
    return self;
}

@end
