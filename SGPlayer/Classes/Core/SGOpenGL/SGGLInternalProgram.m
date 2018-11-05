//
//  SGGLInternalProgram.m
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLInternalProgram.h"
#import "SGMacro.h"

@implementation SGGLInternalProgram

- (instancetype)init
{
    if (self = [super init]) {
        _programID = glCreateProgram();
        
        GLuint vertexShaderID;
        GLuint fragmentShaderID;
        if (![self compileShader:&vertexShaderID type:GL_VERTEX_SHADER string:[self vertexShaderString]]) {
            SGPlayerLog(@"load vertex shader failure");
        }
        if (![self compileShader:&fragmentShaderID type:GL_FRAGMENT_SHADER string:[self fragmentShaderString]]) {
            SGPlayerLog(@"load fragment shader failure");
        }
        glAttachShader(_programID, vertexShaderID);
        glAttachShader(_programID, fragmentShaderID);
        glLinkProgram(_programID);
        if (vertexShaderID) {
            glDeleteShader(vertexShaderID);
            vertexShaderID = 0;
        }
        if (fragmentShaderID) {
            glDeleteShader(fragmentShaderID);
            fragmentShaderID = 0;
        }
        [self loadVariable];
    }
    return self;
}

- (void)dealloc
{
    if (_programID) {
        glDeleteProgram(_programID);
        _programID = 0;
    }
}

- (void)updateModelViewProjectionMatrix:(GLKMatrix4)matrix
{
    glUniformMatrix4fv(self.modelViewProjectionMatrix_location, 1, GL_FALSE, matrix.m);
}

- (void)use
{
    glUseProgram(_programID);
}

- (void)unuse
{
    glUseProgram(0);
}

- (void)loadVariable {};
- (void)bindVariable {};

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(const char *)shaderString
{
    if (!shaderString) {
        SGPlayerLog(@"Failed to load shader");
        return NO;
    }
    GLint status;
    * shader = glCreateShader(type);
    glShaderSource(* shader, 1, &shaderString, NULL);
    glCompileShader(* shader);
    glGetShaderiv(* shader, GL_COMPILE_STATUS, &status);
    if (status != GL_TRUE) {
        GLint logLength;
        glGetShaderiv(* shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar * log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(* shader, logLength, &logLength, log);
            SGPlayerLog(@"Shader compile log:\n%s", log);
            free(log);
        }
    }
    return status == GL_TRUE;
}

@end
