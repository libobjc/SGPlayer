//
//  SGGLBGRAProgram.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/31.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGGLBGRAProgram.h"

#define SG_GLES_STRINGIZE(x) #x

static const char vertex_shader_string[] = SG_GLES_STRINGIZE
(
 attribute vec4 position;
 attribute vec2 textureCoordinate;
 uniform mat4 modelViewProjectionMatrix;
 varying vec2 v_textureCoordinate;
 
 void main()
 {
     v_textureCoordinate = textureCoordinate;
     gl_Position = modelViewProjectionMatrix * position;
 }
 );

#if SGPLATFORM_TARGET_OS_MAC
static const char fragment_shader_string[] = SG_GLES_STRINGIZE
(
 uniform sampler2D Sampler;
 varying vec2 v_textureCoordinate;
 
 void main()
 {
     gl_FragColor = texture2D(Sampler, v_textureCoordinate);
 }
 );
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
static const char fragment_shader_string[] = SG_GLES_STRINGIZE
(
 uniform sampler2D Sampler;
 varying mediump vec2 v_textureCoordinate;
 
 void main()
 {
     gl_FragColor = texture2D(Sampler, v_textureCoordinate);
 }
 );
#endif

@implementation SGGLBGRAProgram

- (const char *)vertexShaderString
{
    return vertex_shader_string;
}

- (const char *)fragmentShaderString
{
    return fragment_shader_string;
}

- (void)loadVariable
{
    self.position_location = glGetAttribLocation(self.programID, "position");
    self.textureCoordinate_location = glGetAttribLocation(self.programID, "textureCoordinate");
    self.modelViewProjectionMatrix_location = glGetUniformLocation(self.programID, "modelViewProjectionMatrix");
    self.sampler_location = glGetUniformLocation(self.programID, "Sampler");
}

- (void)bindVariable
{
    glEnableVertexAttribArray(self.position_location);
    glEnableVertexAttribArray(self.textureCoordinate_location);
    
    glUniform1i(self.sampler_location, 0);
}

@end
