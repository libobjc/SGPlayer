//
//  SGMatrix.m
//  SGPlayer
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGMatrix.h"
#import "SGPlayerMacro.h"

#if SGPLATFORM_TARGET_OS_IPHONE
#import "SGSensors.h"
#endif

@interface SGMatrix ()

#if SGPLATFORM_TARGET_OS_IPHONE
@property (nonatomic, strong) SGSensors * sensors;
#endif

@end

@implementation SGMatrix

- (instancetype)init
{
    if (self = [super init]) {
        [self setupSensors];
    }
    return self;
}

#pragma mark - sensors

- (void)setupSensors
{
#if SGPLATFORM_TARGET_OS_IPHONE
    self.sensors = [[SGSensors alloc] init];
    [self.sensors start];
#endif
}

- (BOOL)singleMatrixWithSize:(CGSize)size matrix:(GLKMatrix4 *)matrix fingerRotation:(SGFingerRotation *)fingerRotation
{
#if SGPLATFORM_TARGET_OS_IPHONE
    if (!self.sensors.isReady) return NO;
#endif

    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, -fingerRotation.x);
#if SGPLATFORM_TARGET_OS_IPHONE
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, self.sensors.modelView);
#endif
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, fingerRotation.y);
    
    float aspect = fabs(size.width / size.height);
    GLKMatrix4 mvpMatrix = GLKMatrix4Identity;
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians([SGFingerRotation degress]), aspect, 0.1f, 400.0f);
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(0, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    mvpMatrix = GLKMatrix4Multiply(projectionMatrix, viewMatrix);
    mvpMatrix = GLKMatrix4Multiply(mvpMatrix, modelViewMatrix);
    
    * matrix = mvpMatrix;
    
    return YES;
}

- (BOOL)doubleMatrixWithSize:(CGSize)size leftMatrix:(GLKMatrix4 *)leftMatrix rightMatrix:(GLKMatrix4 *)rightMatrix
{
#if SGPLATFORM_TARGET_OS_IPHONE
    if (!self.sensors.isReady) return NO;
    GLKMatrix4 modelViewMatrix = self.sensors.modelView;
#else
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
#endif
    
    float aspect = fabs(size.width / 2 / size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians([SGFingerRotation degress]), aspect, 0.1f, 400.0f);
    
    CGFloat distance = 0.012;
    
    GLKMatrix4 leftViewMatrix = GLKMatrix4MakeLookAt(-distance, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    GLKMatrix4 rightViewMatrix = GLKMatrix4MakeLookAt(distance, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    
    GLKMatrix4 leftMvpMatrix = GLKMatrix4Multiply(projectionMatrix, leftViewMatrix);
    GLKMatrix4 rightMvpMatrix = GLKMatrix4Multiply(projectionMatrix, rightViewMatrix);
    
    leftMvpMatrix = GLKMatrix4Multiply(leftMvpMatrix, modelViewMatrix);
    rightMvpMatrix = GLKMatrix4Multiply(rightMvpMatrix, modelViewMatrix);
    
    * leftMatrix = leftMvpMatrix;
    * rightMatrix = rightMvpMatrix;
    
    return YES;
}

- (void)dealloc
{
#if SGPLATFORM_TARGET_OS_IPHONE
    [self.sensors stop];
#endif
    SGPlayerLog(@"%@ release", self.class);
}

@end
