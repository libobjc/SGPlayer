//
//  SGGLYUV420PProgram.h
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLBasicProgram.h"

@interface SGGLYUV420PProgram : SGGLBasicProgram

@property (nonatomic) GLint samplerY_location;
@property (nonatomic) GLint samplerU_location;
@property (nonatomic) GLint samplerV_location;

@end
