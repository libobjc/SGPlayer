//
//  SGGLFFProgram.h
//  SGPlayer
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLProgram.h"

@interface SGGLFFProgram : SGGLProgram

+ (instancetype)program;

@property (nonatomic, assign) GLint samplerY_location;
@property (nonatomic, assign) GLint samplerU_location;
@property (nonatomic, assign) GLint samplerV_location;

@end
