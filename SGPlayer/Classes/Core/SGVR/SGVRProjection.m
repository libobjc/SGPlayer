//
//  SGVRProjection.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVRProjection.h"
#import "SGPLFTargets.h"
#if SGPLATFORM_TARGET_OS_IPHONE
#import "SGMotionSensor.h"
#endif

@interface SGVRProjection ()

#if SGPLATFORM_TARGET_OS_IPHONE
@property (nonatomic, strong) SGMotionSensor * sensor;
#endif
@property (nonatomic) GLKMatrix4 lastMatrix11;
@property (nonatomic) GLKMatrix4 lastMatrix21;
@property (nonatomic) GLKMatrix4 lastMatrix22;
@property (nonatomic) BOOL lastMatrix1Available;
@property (nonatomic) BOOL lastMatrix2Available;

@end

@implementation SGVRProjection

- (instancetype)init
{
    if (self = [super init]) {
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
#if SGPLATFORM_TARGET_OS_IPHONE
    if (!self.sensor) {
        self.sensor = [[SGMotionSensor alloc] init];
        [self.sensor start];
    }
#endif
}

- (void)stop
{
#if SGPLATFORM_TARGET_OS_IPHONE
    if (self.sensor) {
        [self.sensor stop];
        self.sensor = nil;
        self.lastMatrix1Available = NO;
        self.lastMatrix2Available = NO;
    }
#endif
}

- (BOOL)ready
{
#if SGPLATFORM_TARGET_OS_IPHONE
    if (self.viewport.sensorEnable) {
        [self start];
        return self.sensor.ready;
    }
#endif
    return YES;
}

- (BOOL)matrixWithAspect:(Float64)aspect matrix1:(GLKMatrix4 *)matrix1
{
#if SGPLATFORM_TARGET_OS_IPHONE
    if (self.viewport.sensorEnable) {
        [self start];
        if (!self.sensor.ready) {
            if (self.lastMatrix1Available) {
                * matrix1 = self.lastMatrix11;
                return YES;
            }
            return NO;
        }
    }
#endif
    GLKMatrix4 modelMatrix = GLKMatrix4Identity;
    modelMatrix = GLKMatrix4RotateX(modelMatrix, GLKMathDegreesToRadians(self.viewport.y) * (self.viewport.flipY ? -1 : 1));
#if SGPLATFORM_TARGET_OS_IPHONE
    if (self.viewport.sensorEnable) {
        modelMatrix = GLKMatrix4Multiply(modelMatrix, self.sensor.matrix);
    }
#endif
    modelMatrix = GLKMatrix4RotateY(modelMatrix, GLKMathDegreesToRadians(self.viewport.x) * (self.viewport.flipX ? -1 : 1));
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(0, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(self.viewport.degress), aspect, 0.1f, 400.0f);
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, viewMatrix);
    modelViewProjectionMatrix = GLKMatrix4Multiply(modelViewProjectionMatrix, modelMatrix);
    *matrix1 = modelViewProjectionMatrix;
    self.lastMatrix1Available = YES;
    self.lastMatrix11 = modelViewProjectionMatrix;
    return YES;
}

- (BOOL)matrixWithAspect:(Float64)aspect matrix1:(GLKMatrix4 *)matrix1 matrix2:(GLKMatrix4 *)matrix2
{
#if SGPLATFORM_TARGET_OS_IPHONE
    if (self.viewport.sensorEnable) {
        [self start];
        if (!self.sensor.ready) {
            if (self.lastMatrix2Available) {
                * matrix1 = self.lastMatrix21;
                * matrix2 = self.lastMatrix22;
                return YES;
            }
            return NO;
        }
    }
#endif
    float distance = 0.012;
    GLKMatrix4 modelMatrix = GLKMatrix4Identity;
    modelMatrix = GLKMatrix4RotateX(modelMatrix, GLKMathDegreesToRadians(self.viewport.y) * (self.viewport.flipY ? -1 : 1));
#if SGPLATFORM_TARGET_OS_IPHONE
    if (self.viewport.sensorEnable) {
        modelMatrix = GLKMatrix4Multiply(modelMatrix, self.sensor.matrix);
    }
#endif
    GLKMatrix4 leftViewMatrix = GLKMatrix4MakeLookAt(-distance, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    GLKMatrix4 rightViewMatrix = GLKMatrix4MakeLookAt(distance, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(self.viewport.degress), aspect, 0.1f, 400.0f);
    GLKMatrix4 modelViewProjectionMatrix1 = GLKMatrix4Multiply(projectionMatrix, leftViewMatrix);
    GLKMatrix4 modelViewProjectionMatrix2 = GLKMatrix4Multiply(projectionMatrix, rightViewMatrix);
    modelViewProjectionMatrix1 = GLKMatrix4Multiply(modelViewProjectionMatrix1, modelMatrix);
    modelViewProjectionMatrix2 = GLKMatrix4Multiply(modelViewProjectionMatrix2, modelMatrix);
    *matrix1 = modelViewProjectionMatrix1;
    *matrix2 = modelViewProjectionMatrix2;
    self.lastMatrix2Available = YES;
    self.lastMatrix21 = modelViewProjectionMatrix1;
    self.lastMatrix22 = modelViewProjectionMatrix2;
    return YES;
}

@end
