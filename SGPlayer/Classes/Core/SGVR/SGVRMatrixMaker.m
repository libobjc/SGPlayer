//
//  SGVRMatrixMaker.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVRMatrixMaker.h"
#import "SGMotionSensor.h"

@interface SGVRMatrixMaker ()

@property (nonatomic, strong) SGMotionSensor * sensor;

@end

@implementation SGVRMatrixMaker

- (instancetype)init
{
    if (self = [super init])
    {
        self.viewport = [[SGVRViewport alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self stop];
}

- (void)start
{
    if (!self.sensor)
    {
        self.sensor = [[SGMotionSensor alloc] init];
        [self.sensor start];
    }
}

- (void)stop
{
    if (self.sensor)
    {
        [self.sensor stop];
        self.sensor = nil;
    }
}

- (BOOL)ready
{
    if (self.viewport.sensorEnable)
    {
        [self start];
        return self.sensor.ready;
    }
    return YES;
}

- (BOOL)matrixWithAspect:(double)aspect matrix1:(GLKMatrix4 *)matrix1
{
    if (self.viewport.sensorEnable)
    {
        [self start];
        if (!self.sensor.ready)
        {
            return NO;
        }
    }
    GLKMatrix4 modelMatrix = GLKMatrix4Identity;
    modelMatrix = GLKMatrix4RotateX(modelMatrix, GLKMathDegreesToRadians(self.viewport.y) * (self.viewport.flipY ? -1 : 1));
    if (self.viewport.sensorEnable)
    {
        modelMatrix = GLKMatrix4Multiply(modelMatrix, self.sensor.matrix);
    }
    modelMatrix = GLKMatrix4RotateY(modelMatrix, GLKMathDegreesToRadians(self.viewport.x) * (self.viewport.flipX ? -1 : 1));
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(0, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(self.viewport.degress), aspect, 0.1f, 400.0f);
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, viewMatrix);
    modelViewProjectionMatrix = GLKMatrix4Multiply(modelViewProjectionMatrix, modelMatrix);
    * matrix1 = modelViewProjectionMatrix;
    return YES;
}

- (BOOL)matrixWithAspect:(double)aspect matrix1:(GLKMatrix4 *)matrix1 matrix2:(GLKMatrix4 *)matrix2
{
    if (self.viewport.sensorEnable)
    {
        [self start];
        if (!self.sensor.ready)
        {
            return NO;
        }
    }
    float distance = 0.012;
    GLKMatrix4 modelMatrix = self.sensor.matrix;
    GLKMatrix4 leftViewMatrix = GLKMatrix4MakeLookAt(-distance, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    GLKMatrix4 rightViewMatrix = GLKMatrix4MakeLookAt(distance, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(self.viewport.degress), aspect, 0.1f, 400.0f);
    GLKMatrix4 modelViewProjectionMatrix1 = GLKMatrix4Multiply(projectionMatrix, leftViewMatrix);
    GLKMatrix4 modelViewProjectionMatrix2 = GLKMatrix4Multiply(projectionMatrix, rightViewMatrix);
    modelViewProjectionMatrix1 = GLKMatrix4Multiply(modelViewProjectionMatrix1, modelMatrix);
    modelViewProjectionMatrix2 = GLKMatrix4Multiply(modelViewProjectionMatrix2, modelMatrix);
    * matrix1 = modelViewProjectionMatrix1;
    * matrix2 = modelViewProjectionMatrix2;
    return YES;
}

@end
