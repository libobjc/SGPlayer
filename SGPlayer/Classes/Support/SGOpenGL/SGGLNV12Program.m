//
//  SGGLNV12Program.m
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLNV12Program.h"

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
 uniform sampler2D SamplerY;
 uniform sampler2D SamplerUV;
 uniform mat3 colorConversionMatrix;
 varying vec2 v_textureCoordinate;
 
 void main()
 {
     vec3 yuv;
     
     yuv.x = texture2D(SamplerY, v_textureCoordinate).r - (16.0/255.0);
     yuv.yz = texture2D(SamplerUV, v_textureCoordinate).ra - vec2(0.5, 0.5);
     
     vec3 rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1.0);
 }
 );
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
static const char fragment_shader_string[] = SG_GLES_STRINGIZE
(
 precision mediump float;
 
 uniform sampler2D SamplerY;
 uniform sampler2D SamplerUV;
 uniform mat3 colorConversionMatrix;
 varying mediump vec2 v_textureCoordinate;
 
 void main()
 {
     mediump vec3 yuv;
     
     yuv.x = texture2D(SamplerY, v_textureCoordinate).r - (16.0/255.0);
     yuv.yz = texture2D(SamplerUV, v_textureCoordinate).rg - vec2(0.5, 0.5);
     
     lowp vec3 rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );
#endif

@implementation SGGLNV12Program

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
    self.samplerY_location = glGetUniformLocation(self.programID, "SamplerY");
    self.samplerUV_location = glGetUniformLocation(self.programID, "SamplerUV");
    self.colorConversionMatrix_location = glGetUniformLocation(self.programID, "colorConversionMatrix");
}

- (void)bindVariable
{
    glEnableVertexAttribArray(self.position_location);
    glEnableVertexAttribArray(self.textureCoordinate_location);
    
    static GLfloat colorConversion709[] = {
        1.164,    1.164,     1.164,
        0.0,      -0.213,    2.112,
        1.793,    -0.533,    0.0,
    };
    glUniformMatrix3fv(self.colorConversionMatrix_location, 1, GL_FALSE, colorConversion709);
    glUniform1i(self.samplerY_location, 0);
    glUniform1i(self.samplerUV_location, 1);
}

@end
