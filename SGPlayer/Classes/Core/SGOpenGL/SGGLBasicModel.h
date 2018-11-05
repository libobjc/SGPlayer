//
//  SGGLBasicModel.h
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGGLModel.h"

@interface SGGLBasicModel : NSObject <SGGLModel>

- (GLushort *)indexes_data;
- (GLfloat *)vertices_data;
- (GLfloat *)textureCoordinates_data;

- (int)indexes_count;
- (int)vertices_count;

@end
