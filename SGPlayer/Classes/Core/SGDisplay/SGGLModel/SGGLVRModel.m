//
//  SGGLVRModel.m
//  SGPlayer
//
//  Created by Single on 17/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLVRModel.h"

@implementation SGGLVRModel

static GLuint vertex_buffer_id = 0;
static GLuint index_buffer_id = 0;
static GLuint texture_buffer_id = 0;

static GLfloat * vertex_buffer_data = NULL;
static GLushort * index_buffer_data = NULL;
static GLfloat * texture_buffer_data = NULL;

static int const slices_count = 200;
static int const parallels_count = slices_count / 2;

static int const index_count = slices_count * parallels_count * 6;
static int const vertex_count = (slices_count + 1) * (parallels_count + 1);

void setup_vr()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        float const step = (2.0f * M_PI) / (float)slices_count;
        float const radius = 1.0f;
        
        // model
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
        
        glGenBuffers(1, &index_buffer_id);
        glGenBuffers(1, &vertex_buffer_id);
        glGenBuffers(1, &texture_buffer_id);
    });
}

- (void)setupModel
{
    setup_vr();
    self.index_count = index_count;
    self.vertex_count = vertex_count;
    self.index_id = index_buffer_id;
    self.vertex_id = vertex_buffer_id;
    self.texture_id = texture_buffer_id;
}

- (void)bindPositionLocation:(GLint)position_location
        textureCoordLocation:(GLint)textureCoordLocation
{
    [self bindPositionLocation:position_location
          textureCoordLocation:textureCoordLocation
             textureRotateType:SGGLModelTextureRotateType0];
}

- (void)bindPositionLocation:(GLint)position_location
        textureCoordLocation:(GLint)textureCoordLocation
           textureRotateType:(SGGLModelTextureRotateType)textureRotateType
{
    // index
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.index_id);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, self.index_count * sizeof(GLushort), index_buffer_data, GL_STATIC_DRAW);
    
    // vertex
    glBindBuffer(GL_ARRAY_BUFFER, self.vertex_id);
    glBufferData(GL_ARRAY_BUFFER, self.vertex_count * 3 * sizeof(GLfloat), vertex_buffer_data, GL_STATIC_DRAW);
    glEnableVertexAttribArray(position_location);
    glVertexAttribPointer(position_location, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
    
    // texture coord
    glBindBuffer(GL_ARRAY_BUFFER, self.texture_id);
    glBufferData(GL_ARRAY_BUFFER, self.vertex_count * 2 * sizeof(GLfloat), texture_buffer_data, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(textureCoordLocation);
    glVertexAttribPointer(textureCoordLocation, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, NULL);
}


@end
