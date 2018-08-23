//
//  SGMatrix.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/23.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "SGGLDefines.h"

@interface SGMatrix : NSObject

@property (nonatomic, assign, readonly) BOOL ready;
@property (nonatomic, assign) double degress;        // Default value is 60.
@property (nonatomic, assign) double aspect;         // Default value is 1.
@property (nonatomic, assign) double x;              // Default value is 0, range is (-360, 360).
@property (nonatomic, assign) double y;              // Default value is 0, range is (-360, 360).
@property (nonatomic, assign) BOOL flip;             // Default value is NO.
@property (nonatomic, assign) BOOL sensorEnable;     // Default value is YES.

- (BOOL)matrix:(GLKMatrix4 *)matrix;
- (BOOL)leftMatrix:(GLKMatrix4 *)leftMatrix rightMatrix:(GLKMatrix4 *)rightMatrix;

@end
