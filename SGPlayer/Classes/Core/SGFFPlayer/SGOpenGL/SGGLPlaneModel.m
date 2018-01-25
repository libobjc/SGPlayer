//
//  SGGLPlaneModel.m
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLPlaneModel.h"

@implementation SGGLPlaneModel

- (GLushort *)dataOfIndexes
{
    static GLushort dataOfIndexes[] =
    {
        0, 1, 2,
        0, 2, 3,
    };
    return dataOfIndexes;
}

- (GLfloat *)dataOfVertices
{
    static GLfloat dataOfVertices[] =
    {
        -1,  1, 0.0,
         1,  1, 0.0,
         1, -1, 0.0,
        -1, -1, 0.0,
    };
    return dataOfVertices;
}
- (GLfloat *)dataOfTextureCoordinates
{
    static GLfloat dataOfTextureCoordinates[] =
    {
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0,
        0.0, 1.0,
    };
    return dataOfTextureCoordinates;
}

- (int)numberOfIndexes
{
    return 6;
}

- (int)numberOfVertices
{
    return 4;
}

@end
