//
//  SGGLProgram.h
//  SGPlayer
//
//  Created by Single on 2018/1/26.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGGLProgram_h
#define SGGLProgram_h

#import "SGPLFOpenGL.h"

typedef NS_ENUM(uint32_t, SGGLProgramType) {
    SGGLProgramTypeUnknown,
    SGGLProgramTypeYUV420P,
    SGGLProgramTypeNV12,
    SGGLProgramTypeBGRA,
};

@protocol SGGLProgram <NSObject>

- (GLint)position_location;
- (GLint)textureCoordinate_location;
- (GLint)modelViewProjectionMatrix_location;

- (void)use;
- (void)unuse;
- (void)bindVariable;
- (void)updateModelViewProjectionMatrix:(GLKMatrix4)matrix;

@end

#endif /* SGGLProgram_h */
