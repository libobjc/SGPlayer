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

@property (nonatomic, assign) float aspect;

- (BOOL)matrix:(GLKMatrix4 *)matrix;
- (BOOL)leftMatrix:(GLKMatrix4 *)leftMatrix rightMatrix:(GLKMatrix4 *)rightMatrix;

@end
