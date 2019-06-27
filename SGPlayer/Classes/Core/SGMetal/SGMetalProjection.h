//
//  SGMetalProjection.h
//  MetalTest
//
//  Created by Single on 2019/6/26.
//  Copyright © 2019 Single. All rights reserved.
//

#import <simd/simd.h>
#import <Metal/Metal.h>

@interface SGMetalProjection : NSObject

@property (nonatomic) MTLSize inputSize;
@property (nonatomic) MTLSize outputSize;

- (MTLViewport)viewport;
- (matrix_float4x4)modelViewProjection;

@end
