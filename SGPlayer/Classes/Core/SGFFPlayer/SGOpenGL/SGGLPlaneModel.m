//
//  SGGLPlaneModel.m
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLPlaneModel.h"

@implementation SGGLPlaneModel

- (GLushort *)indexes_data
{
    static GLushort indexes_data[] =
    {
        0, 1, 2,
        0, 2, 3,
    };
    return indexes_data;
}

- (GLfloat *)vertices_data
{
    static GLfloat vertices_data[] =
    {
        -1,  1, 0.0,
         1,  1, 0.0,
         1, -1, 0.0,
        -1, -1, 0.0,
    };
    return vertices_data;
}
- (GLfloat *)textureCoordinates_data
{
    static GLfloat textureCoordinates_data[] =
    {
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0,
        0.0, 1.0,
    };
    return textureCoordinates_data;
}

- (int)indexes_count
{
    return 6;
}

- (int)vertices_count
{
    return 4;
}

@end
