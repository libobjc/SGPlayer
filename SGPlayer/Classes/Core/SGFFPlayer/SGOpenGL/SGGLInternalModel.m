//
//  SGGLInternalModel.m
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLInternalModel.h"

@interface SGGLInternalModel ()

{
    GLuint _idOfIndexes;
    GLuint _idOfVertices;
    GLuint _idOfTextureCoordinates;
    GLushort * _dataOfIndexes;
    GLfloat * _dataOfVertices;
    GLfloat * _dataOfTextureCoordinates;
    int _numberOfIndexes;
    int _numberOfVertices;
}

@end

@implementation SGGLInternalModel

- (instancetype)init
{
    if (self = [super init])
    {
        _dataOfIndexes = [self dataOfIndexes];
        _dataOfVertices = [self dataOfVertices];
        _dataOfTextureCoordinates = [self dataOfTextureCoordinates];
        _numberOfIndexes = [self numberOfIndexes];
        _numberOfVertices = [self numberOfVertices];
        
        glGenBuffers(1, &_idOfIndexes);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _idOfIndexes);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, _numberOfIndexes * sizeof(GLushort), _dataOfIndexes, GL_STATIC_DRAW);
        
        glGenBuffers(1, &_idOfVertices);
        glBindBuffer(GL_ARRAY_BUFFER, _idOfVertices);
        glBufferData(GL_ARRAY_BUFFER, _numberOfVertices * 3 * sizeof(GLfloat), _dataOfVertices, GL_STATIC_DRAW);
        
        glGenBuffers(1, &_idOfTextureCoordinates);
        glBindBuffer(GL_ARRAY_BUFFER, _idOfTextureCoordinates);
        glBufferData(GL_ARRAY_BUFFER, _numberOfVertices * 2 * sizeof(GLfloat), _dataOfTextureCoordinates, GL_DYNAMIC_DRAW);
        
        [self bindEmpty];
    }
    return self;
}

- (void)dealloc
{
    if (_idOfIndexes)
    {
        glDeleteBuffers(1, &_idOfIndexes);
        _idOfIndexes = 0;
    }
    if (_idOfVertices)
    {
        glDeleteBuffers(1, &_idOfVertices);
        _idOfVertices = 0;
    }
    if (_idOfTextureCoordinates)
    {
        glDeleteBuffers(1, &_idOfTextureCoordinates);
        _idOfTextureCoordinates = 0;
    }
}

- (void)bindPositionLocation:(GLint)positionLocation textureCoordLocation:(GLint)textureCoordLocation
{
    glBindBuffer(GL_ARRAY_BUFFER, _idOfVertices);
    glEnableVertexAttribArray(positionLocation);
    glVertexAttribPointer(positionLocation, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, _idOfTextureCoordinates);
    glEnableVertexAttribArray(textureCoordLocation);
    glVertexAttribPointer(textureCoordLocation, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, NULL);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _idOfIndexes);
}

- (void)bindEmpty
{
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

- (void)draw
{
    glDrawElements(GL_TRIANGLES, _numberOfIndexes, GL_UNSIGNED_SHORT, 0);
}

- (GLushort *)dataOfIndexes {return nil;}
- (GLfloat *)dataOfVertices {return nil;}
- (GLfloat *)dataOfTextureCoordinates {return nil;}

- (int)numberOfIndexes {return 0;}
- (int)numberOfVertices {return 0;}

@end
