//
//  SGGLAVProgram.h
//  SGPlayer
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLProgram.h"

@interface SGGLAVProgram : SGGLProgram

+ (instancetype)program;

@property (nonatomic, assign) GLint samplerY_location;
@property (nonatomic, assign) GLint samplerUV_location;
@property (nonatomic, assign) GLint colorConversionMatrix_location;

@end
