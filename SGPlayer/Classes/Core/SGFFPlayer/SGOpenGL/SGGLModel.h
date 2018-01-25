//
//  SGGLModel.h
//  SGPlayer
//
//  Created by Single on 2018/1/24.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGGLModel_h
#define SGGLModel_h


#import "SGPLFOpenGL.h"


@protocol SGGLModel <NSObject>

- (void)bindPositionLocation:(GLint)positionLocation
   textureCoordinateLocation:(GLint)textureCoordinateLocation;
- (void)bindEmpty;
- (void)draw;

@end


#endif /* SGGLModel_h */
