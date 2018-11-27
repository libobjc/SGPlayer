//
//  SGGLBasicModel.m
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLBasicModel.h"

@interface SGGLBasicModel ()

{
    GLuint _indexes_buffer_id;
    GLuint _vertices_buffer_id;
    GLuint _textureCoordinates_buffer_id;
    
    GLushort *_indexes_buffer_data;
    GLfloat *_vertices_buffer_data;
    GLfloat *_textureCoordinates_buffer_data;
    
    int _indexes_count;
    int _vertices_count;
}

@end

@implementation SGGLBasicModel

- (instancetype)init
{
    if (self = [super init]) {
        _indexes_buffer_data = [self indexes_data];
        _vertices_buffer_data = [self vertices_data];
        _textureCoordinates_buffer_data = [self textureCoordinates_data];
        
        _indexes_count = [self indexes_count];
        _vertices_count = [self vertices_count];
        
        glGenBuffers(1, &_indexes_buffer_id);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexes_buffer_id);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, _indexes_count * sizeof(GLushort), _indexes_buffer_data, GL_STATIC_DRAW);
        
        glGenBuffers(1, &_vertices_buffer_id);
        glBindBuffer(GL_ARRAY_BUFFER, _vertices_buffer_id);
        glBufferData(GL_ARRAY_BUFFER, _vertices_count * 3 * sizeof(GLfloat), _vertices_buffer_data, GL_STATIC_DRAW);
        
        glGenBuffers(1, &_textureCoordinates_buffer_id);
        glBindBuffer(GL_ARRAY_BUFFER, _textureCoordinates_buffer_id);
        glBufferData(GL_ARRAY_BUFFER, _vertices_count * 2 * sizeof(GLfloat), _textureCoordinates_buffer_data, GL_DYNAMIC_DRAW);
        
        [self unbind];
    }
    return self;
}

- (void)dealloc
{
    if (_indexes_buffer_id) {
        glDeleteBuffers(1, &_indexes_buffer_id);
        _indexes_buffer_id = 0;
    }
    if (_vertices_buffer_id) {
        glDeleteBuffers(1, &_vertices_buffer_id);
        _vertices_buffer_id = 0;
    }
    if (_textureCoordinates_buffer_id) {
        glDeleteBuffers(1, &_textureCoordinates_buffer_id);
        _textureCoordinates_buffer_id = 0;
    }
}

- (void)bindPosition_location:(GLint)position_location textureCoordinate_location:(GLint)textureCoordinate_location;
{
    glBindBuffer(GL_ARRAY_BUFFER, _vertices_buffer_id);
    glEnableVertexAttribArray(position_location);
    glVertexAttribPointer(position_location, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, _textureCoordinates_buffer_id);
    glEnableVertexAttribArray(textureCoordinate_location);
    glVertexAttribPointer(textureCoordinate_location, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 2, NULL);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexes_buffer_id);
}

- (void)unbind
{
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

- (void)draw
{
    glDrawElements(GL_TRIANGLES, _indexes_count, GL_UNSIGNED_SHORT, 0);
}

- (GLushort *)indexes_data {return nil;}
- (GLfloat *)vertices_data {return nil;}
- (GLfloat *)textureCoordinates_data {return nil;}

- (int)indexes_count {return 0;}
- (int)vertices_count {return 0;}

@end
