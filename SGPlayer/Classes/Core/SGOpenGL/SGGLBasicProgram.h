//
//  SGGLBasicProgram.h
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGGLProgram.h"

@interface SGGLBasicProgram : NSObject <SGGLProgram>

@property (nonatomic, readonly) GLint programID;

#pragma mark - Override

@property (nonatomic, readonly) const char *vertexShaderString;
@property (nonatomic, readonly) const char *fragmentShaderString;

@property (nonatomic) GLint position_location;
@property (nonatomic) GLint textureCoordinate_location;
@property (nonatomic) GLint modelViewProjectionMatrix_location;

- (void)loadVariable;

@end
