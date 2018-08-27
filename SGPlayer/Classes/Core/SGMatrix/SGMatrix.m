//
//  SGMatrix.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGMatrix.h"
#import "SGSensor.h"

@interface SGMatrix ()

@property (nonatomic, strong) SGSensor * sensor;

@end

@implementation SGMatrix

- (instancetype)init
{
    if (self = [super init])
    {
        self.degress = 60;
        self.aspect = 1;
        self.x = 0;
        self.y = 0;
        self.flip = NO;
        self.sensorEnable = YES;
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
        self.sensor = [[SGSensor alloc] init];
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
    if (self.sensorEnable)
    {
        [self start];
        return self.sensor.ready;
    }
    return YES;
}

- (BOOL)matrix:(GLKMatrix4 *)matrix
{
    if (self.sensorEnable)
    {
        [self start];
        if (!self.sensor.ready)
        {
            return NO;
        }
    }
    GLKMatrix4 modelMatrix = GLKMatrix4Identity;
    modelMatrix = GLKMatrix4RotateX(modelMatrix, GLKMathDegreesToRadians(self.y) * (self.flip ? -1 : 1));
    if (self.sensorEnable)
    {
        modelMatrix = GLKMatrix4Multiply(modelMatrix, self.sensor.matrix);
    }
    modelMatrix = GLKMatrix4RotateY(modelMatrix, GLKMathDegreesToRadians(self.x));
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(0, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(self.degress), self.aspect, 0.1f, 400.0f);
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, viewMatrix);
    modelViewProjectionMatrix = GLKMatrix4Multiply(modelViewProjectionMatrix, modelMatrix);
    * matrix = modelViewProjectionMatrix;
    return YES;
}

- (BOOL)leftMatrix:(GLKMatrix4 *)leftMatrix rightMatrix:(GLKMatrix4 *)rightMatrix
{
    if (self.sensorEnable)
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
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(self.degress), self.aspect, 0.1f, 400.0f);
    GLKMatrix4 leftModelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, leftViewMatrix);
    GLKMatrix4 rightModelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, rightViewMatrix);
    leftModelViewProjectionMatrix = GLKMatrix4Multiply(leftModelViewProjectionMatrix, modelMatrix);
    rightModelViewProjectionMatrix = GLKMatrix4Multiply(rightModelViewProjectionMatrix, modelMatrix);
    * leftMatrix = leftModelViewProjectionMatrix;
    * rightMatrix = rightModelViewProjectionMatrix;
    return YES;
}

@end
