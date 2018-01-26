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


@protocol SGGLProgram <NSObject>

- (GLint)position_location;
- (GLint)textureCoordinate_location;
- (GLint)modelViewProjectionMatrix_location;

- (void)use;
- (void)bindVariable;
- (void)updateModelViewProjectionMatrix:(GLKMatrix4)matrix;

@end


#endif /* SGGLProgram_h */
