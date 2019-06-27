//
//  SGMetalProjection.m
//  MetalTest
//
//  Created by Single on 2019/6/26.
//  Copyright © 2019 Single. All rights reserved.
//

#import "SGMetalProjection.h"
#import "SGMetalUtilities.h"

@implementation SGMetalProjection

- (MTLViewport)viewport
{
    return SGViewportMake(self.inputSize, self.outputSize);
}

- (matrix_float4x4)modelViewProjection
{
    return SGMatrixFloat4x4FromGLKMatrix4(GLKMatrix4Identity);
    static float rotateY = 0;
    GLKMatrix4 model = GLKMatrix4Identity;
    model = GLKMatrix4RotateX(model, GLKMathDegreesToRadians(0));
    model = GLKMatrix4RotateY(model, GLKMathDegreesToRadians(rotateY += 0.5));
    GLKMatrix4 view = GLKMatrix4MakeLookAt(0, 0, 3, 0, 0, -1, 0, 1, 0);
    GLKMatrix4 projection = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(60), 1, 0.1, 400);
    GLKMatrix4 modelViewProjection = projection;
    modelViewProjection = GLKMatrix4Multiply(modelViewProjection, view);
    modelViewProjection = GLKMatrix4Multiply(modelViewProjection, model);
    return SGMatrixFloat4x4FromGLKMatrix4(modelViewProjection);
}

@end
