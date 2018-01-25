//
//  SGGLPlaneModel.m
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLPlaneModel.h"

static GLKVector3 vertex_buffer_data[] =
{
    {-1, 1, 0.0},
    {1, 1, 0.0},
    {1, -1, 0.0},
    {-1, -1, 0.0},
};

static GLushort index_buffer_data[] =
{
    0, 1, 2, 0, 2, 3
};

static GLKVector2 texture_buffer_data[] =
{
    {0.0, 0.0},
    {1.0, 0.0},
    {1.0, 1.0},
    {0.0, 1.0},
};

static int const index_count = 6;
static int const vertex_count = 4;

@interface SGGLPlaneModel ()

{
    GLuint _index_buffer_id;
    GLuint _vertex_buffer_id;
    GLuint _texture_buffer_id;
    int _index_count;
    int _vertex_count;
}

@end

@implementation SGGLPlaneModel

- (instancetype)init
{
    if (self = [super init])
    {
        _index_count = index_count;
        _vertex_count = vertex_count;
        
        glGenBuffers(1, &_index_buffer_id);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _index_buffer_id);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, _index_count * sizeof(GLushort), index_buffer_data, GL_STATIC_DRAW);
        
        glGenBuffers(1, &_vertex_buffer_id);
        glBindBuffer(GL_ARRAY_BUFFER, _vertex_buffer_id);
        glBufferData(GL_ARRAY_BUFFER, _vertex_count * 3 * sizeof(GLfloat), vertex_buffer_data, GL_STATIC_DRAW);
        
        glGenBuffers(1, &_texture_buffer_id);
        glBindBuffer(GL_ARRAY_BUFFER, _texture_buffer_id);
        glBufferData(GL_ARRAY_BUFFER, _vertex_count * 2 * sizeof(GLfloat), texture_buffer_data, GL_DYNAMIC_DRAW);
        
        [self bindEmpty];
    }
    return self;
}

- (void)bindPositionLocation:(GLint)positionLocation textureCoordLocation:(GLint)textureCoordLocation
{
    glBindBuffer(GL_ARRAY_BUFFER, _vertex_buffer_id);
    glEnableVertexAttribArray(positionLocation);
    glVertexAttribPointer(positionLocation, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, _texture_buffer_id);
    glEnableVertexAttribArray(textureCoordLocation);
    glVertexAttribPointer(textureCoordLocation, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, NULL);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _index_buffer_id);
}

- (void)bindEmpty
{
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

- (void)draw
{
    glDrawElements(GL_TRIANGLES, _index_count, GL_UNSIGNED_SHORT, 0);
}

@end
