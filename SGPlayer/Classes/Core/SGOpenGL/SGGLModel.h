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

typedef NS_ENUM(uint32_t, SGGLModelType)
{
    SGGLModelTypeUnknown,
    SGGLModelTypePlane,
    SGGLModelTypeSphere,
};

@protocol SGGLModel <NSObject>

- (void)bindPosition_location:(GLint)position_location textureCoordinate_location:(GLint)textureCoordinate_location;
- (void)unbind;
- (void)draw;

@end

#endif /* SGGLModel_h */
