//
//  SGGLInternalProgram.h
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGGLProgram.h"

@interface SGGLInternalProgram : NSObject <SGGLProgram>

@property (nonatomic, assign, readonly) GLint programID;

#pragma mark - Override

@property (nonatomic, assign, readonly) const char * vertexShaderString;
@property (nonatomic, assign, readonly) const char * fragmentShaderString;

@property (nonatomic, assign) GLint position_location;
@property (nonatomic, assign) GLint textureCoordinate_location;
@property (nonatomic, assign) GLint modelViewProjectionMatrix_location;

- (void)loadVariable;

@end
