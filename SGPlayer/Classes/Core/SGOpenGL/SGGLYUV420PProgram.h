//
//  SGGLYUV420PProgram.h
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLBasicProgram.h"

@interface SGGLYUV420PProgram : SGGLBasicProgram

@property (nonatomic, assign) GLint samplerY_location;
@property (nonatomic, assign) GLint samplerU_location;
@property (nonatomic, assign) GLint samplerV_location;

@end
