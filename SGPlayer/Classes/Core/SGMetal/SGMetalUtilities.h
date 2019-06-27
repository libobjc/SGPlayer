//
//  SGMetalUtilities.h
//  MetalTest
//
//  Created by Single on 2019/6/25.
//  Copyright © 2019 Single. All rights reserved.
//

#import <simd/simd.h>
#import <GLKit/GLKit.h>
#import <Metal/Metal.h>

MTLViewport SGViewportMake(MTLSize input, MTLSize output);
matrix_float4x4 SGMatrixFloat4x4FromGLKMatrix4(GLKMatrix4 matrix);
