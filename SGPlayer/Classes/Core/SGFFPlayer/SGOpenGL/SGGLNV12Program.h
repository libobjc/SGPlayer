//
//  SGGLNV12Program.h
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLInternalProgram.h"

@interface SGGLNV12Program : SGGLInternalProgram

@property (nonatomic, assign) GLint samplerY_location;
@property (nonatomic, assign) GLint samplerUV_location;
@property (nonatomic, assign) GLint colorConversionMatrix_location;

@end
