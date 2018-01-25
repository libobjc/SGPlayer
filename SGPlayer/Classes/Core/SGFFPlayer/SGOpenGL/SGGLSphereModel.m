//
//  SGGLSphereModel.m
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLSphereModel.h"

static GLushort * index_buffer_data = nil;
static GLfloat * vertex_buffer_data = nil;
static GLfloat * texture_buffer_data = nil;

static int const slices_count = 200;
static int const parallels_count = slices_count / 2;

static int const index_count = slices_count * parallels_count * 6;
static int const vertex_count = (slices_count + 1) * (parallels_count + 1);

@interface SGGLSphereModel ()

{
    GLuint _index_buffer_id;
    GLuint _vertex_buffer_id;
    GLuint _texture_buffer_id;
    int _index_count;
    int _vertex_count;
}

@end

@implementation SGGLSphereModel

- (instancetype)init
{
    if (self = [super init])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
            float const step = (2.0f * M_PI) / (float)slices_count;
            float const radius = 1.0f;
            
            index_buffer_data = malloc(sizeof(GLushort) * index_count);
            vertex_buffer_data = malloc(sizeof(GLfloat) * 3 * vertex_count);
            texture_buffer_data = malloc(sizeof(GLfloat) * 2 * vertex_count);
            
            int runCount = 0;
            for (int i = 0; i < parallels_count + 1; i++)
            {
                for (int j = 0; j < slices_count + 1; j++)
                {
                    int vertex = (i * (slices_count + 1) + j) * 3;
                    if (vertex_buffer_data)
                    {
                        vertex_buffer_data[vertex + 0] = radius * sinf(step * (float)i) * cosf(step * (float)j);
                        vertex_buffer_data[vertex + 1] = radius * cosf(step * (float)i);
                        vertex_buffer_data[vertex + 2] = radius * sinf(step * (float)i) * sinf(step * (float)j);
                    }
                    if (texture_buffer_data)
                    {
                        int textureIndex = (i * (slices_count + 1) + j) * 2;
                        texture_buffer_data[textureIndex + 0] = (float)j / (float)slices_count;
                        texture_buffer_data[textureIndex + 1] = ((float)i / (float)parallels_count);
                    }
                    if (index_buffer_data && i < parallels_count && j < slices_count)
                    {
                        index_buffer_data[runCount++] = i * (slices_count + 1) + j;
                        index_buffer_data[runCount++] = (i + 1) * (slices_count + 1) + j;
                        index_buffer_data[runCount++] = (i + 1) * (slices_count + 1) + (j + 1);
                        
                        index_buffer_data[runCount++] = i * (slices_count + 1) + j;
                        index_buffer_data[runCount++] = (i + 1) * (slices_count + 1) + (j + 1);
                        index_buffer_data[runCount++] = i * (slices_count + 1) + (j + 1);
                    }
                }
            }
        });
        
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
