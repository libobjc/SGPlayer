//
//  SGMetalUtilities.m
//  MetalTest
//
//  Created by Single on 2019/6/25.
//  Copyright © 2019 Single. All rights reserved.
//

#import "SGMetalUtilities.h"

MTLViewport SGViewportMake(MTLSize input, MTLSize output)
{
    MTLViewport viewport = {0, 0, 0, 0, 0, 0};
    double inputAspect = (double)input.width / (double)input.height;
    double outputAspect = (double)output.width / (double)output.height;
//    if (fabs(outputAspect - inputAspect) <= 0.0001) {
//
//    } else if (outputAspect < inputAspect) {
//        double width = output.height * inputAspect;
//        viewport.originX = (output.width - width) / 2;
//        viewport.originY = 0;
//        viewport.width = width;
//        viewport.height = output.height;
//    } else if (outputAspect > inputAspect) {
//        double height = output.width / inputAspect;
//        viewport.originX = 0;
//        viewport.originY = (output.height - height) / 2;
//        viewport.width = output.width;
//        viewport.height = height;
//    }
    if (fabs(outputAspect - inputAspect) <= 0.0001) {
        
    } else if (outputAspect < inputAspect) {
        double height = output.width / inputAspect;
        viewport.originX = 0;
        viewport.originY = (output.height - height) / 2;
        viewport.width = output.width;
        viewport.height = height;
    } else if (outputAspect > inputAspect) {
        double width = output.height * inputAspect;
        viewport.originX = (output.width - width) / 2;
        viewport.originY = 0;
        viewport.width = width;
        viewport.height = output.height;
    }
    return viewport;
}

matrix_float4x4 SGMatrixFloat4x4FromGLKMatrix4(GLKMatrix4 matrix)
{
    return (matrix_float4x4){{
        {matrix.m00, matrix.m01, matrix.m02, matrix.m03},
        {matrix.m10, matrix.m11, matrix.m12, matrix.m13},
        {matrix.m20, matrix.m21, matrix.m22, matrix.m23},
        {matrix.m30, matrix.m31, matrix.m32, matrix.m33}}};
}
