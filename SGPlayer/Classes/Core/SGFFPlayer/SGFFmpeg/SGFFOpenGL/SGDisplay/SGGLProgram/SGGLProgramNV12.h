//
//  SGGLProgramNV12.h
//  SGPlayer
//
//  Created by Single on 2017/3/27.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGGLProgram.h"

@interface SGGLProgramNV12 : SGGLProgram

+ (instancetype)program;

@property (nonatomic, assign) GLint samplerY_location;
@property (nonatomic, assign) GLint samplerUV_location;
@property (nonatomic, assign) GLint colorConversionMatrix_location;

@end
