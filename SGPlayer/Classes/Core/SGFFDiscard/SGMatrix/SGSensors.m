//
//  SGSensors.m
//  SGPlayer
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGSensors.h"
#import <CoreMotion/CoreMotion.h>

@interface SGSensors ()

@property (nonatomic, strong) CMMotionManager * manager;
@property (nonatomic, assign) UIInterfaceOrientation orientation;
@property (nonatomic, assign) CGFloat defalutRotateY;
@property (nonatomic, assign) GLKMatrix4 deviceToDisplay;
@property (nonatomic, assign) GLKMatrix4 worldToInertialReferenceFrame;

@end

@implementation SGSensors

- (instancetype)init
{
    if (self = [super init]) {
        self.manager = [[CMMotionManager alloc] init];
        self.worldToInertialReferenceFrame = [self getRotateEulerMatrixX:-90 Y:0 Z:90];
        self.deviceToDisplay = GLKMatrix4Identity;
        switch ([UIApplication sharedApplication].statusBarOrientation) {
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationUnknown:
            case UIInterfaceOrientationPortraitUpsideDown:
            {
                self.defalutRotateY = 0;
            }
                break;
            case UIInterfaceOrientationLandscapeRight:
            {
                self.defalutRotateY = -90;
            }
                break;
            case UIInterfaceOrientationLandscapeLeft:
            {
                self.defalutRotateY = 90;
            }
                break;
        }
    }
    return self;
}

- (void)updateDeviceOrientation:(UIInterfaceOrientation)orientation
{
    self.orientation = orientation;
}

- (void)setOrientation:(UIInterfaceOrientation)orientation
{
    if (_orientation != orientation) {
        _orientation = orientation;
        switch (orientation) {
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationUnknown:
            {
                self.deviceToDisplay = GLKMatrix4Identity;
            }
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
            {
                self.deviceToDisplay = [self getRotateEulerMatrixX:0 Y:0 Z:180];
            }
                break;
            case UIInterfaceOrientationLandscapeRight:
            {
                self.deviceToDisplay = [self getRotateEulerMatrixX:0 Y:0 Z:-90];
            }
                break;
            case UIInterfaceOrientationLandscapeLeft:
            {
                self.deviceToDisplay = [self getRotateEulerMatrixX:0 Y:0 Z:90];
            }
                break;
        }
    }
}

- (BOOL)isReady
{
    if (self.manager.isDeviceMotionAvailable) {
        return self.manager.deviceMotion && self.manager.isDeviceMotionActive;
    } else {
        return YES;
    }
}

- (void)start
{
    if (!self.isReady && !self.manager.isDeviceMotionActive) {
        self.manager.deviceMotionUpdateInterval = 0.01;
        [self.manager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];
    }
}

- (void)stop
{
    [self.manager stopDeviceMotionUpdates];
    self.manager = nil;
}

- (GLKMatrix4)modelView
{
    if (!self.manager.isDeviceMotionAvailable || !self.manager.isDeviceMotionActive) {
        return GLKMatrix4Identity;
    }
    
    CMDeviceMotion * motion = self.manager.deviceMotion;
    if (!motion) return GLKMatrix4Identity;
    
    [self updateDeviceOrientation:[UIApplication sharedApplication].statusBarOrientation];
    CMRotationMatrix rotationMatrix = motion.attitude.rotationMatrix;
    GLKMatrix4 inertialReferenceFrameToDevice = GLKMatrix4Transpose([self glMatrixFromRotationMatrix:rotationMatrix]);
    GLKMatrix4 worldToDevice = GLKMatrix4Multiply(inertialReferenceFrameToDevice, self.worldToInertialReferenceFrame);
    GLKMatrix4 worldToDisplay = GLKMatrix4Multiply(self.deviceToDisplay, worldToDevice);
    
    worldToDisplay = GLKMatrix4RotateY(worldToDisplay, GLKMathDegreesToRadians(self.defalutRotateY));
    return worldToDisplay;
}

- (GLKMatrix4)glMatrixFromRotationMatrix:(CMRotationMatrix)rotationMatrix
{
    GLKMatrix4 glRotationMatrix;
    
    glRotationMatrix.m00 = rotationMatrix.m11;
    glRotationMatrix.m01 = rotationMatrix.m12;
    glRotationMatrix.m02 = rotationMatrix.m13;
    glRotationMatrix.m03 = 0.0f;
    
    glRotationMatrix.m10 = rotationMatrix.m21;
    glRotationMatrix.m11 = rotationMatrix.m22;
    glRotationMatrix.m12 = rotationMatrix.m23;
    glRotationMatrix.m13 = 0.0f;
    
    glRotationMatrix.m20 = rotationMatrix.m31;
    glRotationMatrix.m21 = rotationMatrix.m32;
    glRotationMatrix.m22 = rotationMatrix.m33;
    glRotationMatrix.m23 = 0.0f;
    
    glRotationMatrix.m30 = 0.0f;
    glRotationMatrix.m31 = 0.0f;
    glRotationMatrix.m32 = 0.0f;
    glRotationMatrix.m33 = 1.0f;
    
    return glRotationMatrix;
}

- (GLKMatrix4)getRotateEulerMatrixX:(CGFloat)x Y:(CGFloat)y Z:(CGFloat)z
{
    x *= (float)(M_PI / 180.0f);
    y *= (float)(M_PI / 180.0f);
    z *= (float)(M_PI / 180.0f);
    float cx = (float) cos(x);
    float sx = (float) sin(x);
    float cy = (float) cos(y);
    float sy = (float) sin(y);
    float cz = (float) cos(z);
    float sz = (float) sin(z);
    float cxsy = cx * sy;
    float sxsy = sx * sy;
    GLKMatrix4 matrix;
    matrix.m[0] = cy * cz;
    matrix.m[1] = -cy * sz;
    matrix.m[2] = sy;
    matrix.m[3] = 0.0f;
    matrix.m[4] = cxsy * cz + cx * sz;
    matrix.m[5] = -cxsy * sz + cx * cz;
    matrix.m[6] = -sx * cy;
    matrix.m[7] = 0.0f;
    matrix.m[8] = -sxsy * cz + sx * sz;
    matrix.m[9] = sxsy * sz + sx * cz;
    matrix.m[10] = cx * cy;
    matrix.m[11] = 0.0f;
    matrix.m[12] = 0.0f;
    matrix.m[13] = 0.0f;
    matrix.m[14] = 0.0f;
    matrix.m[15] = 1.0f;
    return matrix;
}

@end
