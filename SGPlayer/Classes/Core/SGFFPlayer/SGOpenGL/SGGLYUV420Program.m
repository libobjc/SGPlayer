//
//  SGGLYUV420Program.m
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLYUV420Program.h"

#define SG_GLES_STRINGIZE(x) #x

static const char vertex_shader_string[] = SG_GLES_STRINGIZE
(
 attribute vec4 position;
 attribute vec2 textureCoord;
 uniform mat4 mvp_matrix;
 varying vec2 v_textureCoord;
 
 void main()
 {
     v_textureCoord = textureCoord;
     gl_Position = mvp_matrix * position;
 }
 );

#if SGPLATFORM_TARGET_OS_MAC
static const char fragment_shader_string[] = SG_GLES_STRINGIZE
(
 uniform sampler2D SamplerY;
 uniform sampler2D SamplerU;
 uniform sampler2D SamplerV;
 varying vec2 v_textureCoord;
 
 void main()
 {
     float y = texture2D(SamplerY, v_textureCoord).r;
     float u = texture2D(SamplerU, v_textureCoord).r - 0.5;
     float v = texture2D(SamplerV, v_textureCoord).r - 0.5;
     
     float r = y +             1.402 * v;
     float g = y - 0.344 * u - 0.714 * v;
     float b = y + 1.772 * u;
     
     gl_FragColor = vec4(r , g, b, 1.0);
 }
 );
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
static const char fragment_shader_string[] = SG_GLES_STRINGIZE
(
 uniform sampler2D SamplerY;
 uniform sampler2D SamplerU;
 uniform sampler2D SamplerV;
 varying mediump vec2 v_textureCoord;
 
 void main()
 {
     highp float y = texture2D(SamplerY, v_textureCoord).r;
     highp float u = texture2D(SamplerU, v_textureCoord).r - 0.5;
     highp float v = texture2D(SamplerV, v_textureCoord).r - 0.5;
     
     highp float r = y +             1.402 * v;
     highp float g = y - 0.344 * u - 0.714 * v;
     highp float b = y + 1.772 * u;
     
     gl_FragColor = vec4(r , g, b, 1.0);
 }
 );
#endif

@implementation SGGLYUV420Program

- (const char *)vertex_shader_string
{
    return vertex_shader_string;
}

- (const char *)fragment_shader_string
{
    return fragment_shader_string;
}

- (void)loadVariable
{
    self.position_location = glGetAttribLocation(self.programID, "position");
    self.texture_coordinate_location = glGetAttribLocation(self.programID, "textureCoord");
    self.model_view_projection_location = glGetUniformLocation(self.programID, "mvp_matrix");
    self.samplerY_location = glGetUniformLocation(self.programID, "SamplerY");
    self.samplerU_location = glGetUniformLocation(self.programID, "SamplerU");
    self.samplerV_location = glGetUniformLocation(self.programID, "SamplerV");
}

- (void)bindVariable
{
    glEnableVertexAttribArray(self.position_location);
    glEnableVertexAttribArray(self.texture_coordinate_location);
    
    glUniform1i(self.samplerY_location, 0);
    glUniform1i(self.samplerU_location, 1);
    glUniform1i(self.samplerV_location, 2);
}

@end
