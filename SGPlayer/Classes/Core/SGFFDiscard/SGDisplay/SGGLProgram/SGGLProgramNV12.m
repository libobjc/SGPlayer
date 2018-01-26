//
//  SGGLProgramNV12.m
//  SGPlayer
//
//  Created by Single on 2017/3/27.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGGLProgramNV12.h"

#define SG_GLES_STRINGIZE(x) #x

static const char vertexShaderString[] = SG_GLES_STRINGIZE
(
 attribute vec4 position;
 attribute vec2 textureCoord;
 uniform mat4 mpv_matrix;
 varying vec2 v_textureCoord;
 
 void main()
 {
     v_textureCoord = textureCoord;
     gl_Position = mpv_matrix * position;
 }
 );

#if SGPLATFORM_TARGET_OS_MAC
static const char fragmentShaderString[] = SG_GLES_STRINGIZE
(
 uniform sampler2D SamplerY;
 uniform sampler2D SamplerUV;
 uniform mat3 colorConversionMatrix;
 varying vec2 v_textureCoord;
 
 void main()
 {
     vec3 yuv;
     
     yuv.x = texture2D(SamplerY, v_textureCoord).r - (16.0/255.0);
     yuv.yz = texture2D(SamplerUV, v_textureCoord).ra - vec2(0.5, 0.5);
     
     vec3 rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1.0);
 }
 );
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
static const char fragmentShaderString[] = SG_GLES_STRINGIZE
(
 precision mediump float;
 
 uniform sampler2D SamplerY;
 uniform sampler2D SamplerUV;
 uniform mat3 colorConversionMatrix;
 varying mediump vec2 v_textureCoord;
 
 void main()
 {
     mediump vec3 yuv;
     
     yuv.x = texture2D(SamplerY, v_textureCoord).r - (16.0/255.0);
     yuv.yz = texture2D(SamplerUV, v_textureCoord).rg - vec2(0.5, 0.5);
     
     lowp vec3 rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );
#endif

@implementation SGGLProgramNV12

+ (instancetype)program
{
    return [self programWithVertexShader:[NSString stringWithUTF8String:vertexShaderString]
                          fragmentShader:[NSString stringWithUTF8String:fragmentShaderString]];
}

- (void)bindVariable
{
    glEnableVertexAttribArray(self.position_location);
    glEnableVertexAttribArray(self.texture_coord_location);
    
    static GLfloat colorConversion709[] = {
        1.164,    1.164,     1.164,
        0.0,      -0.213,    2.112,
        1.793,    -0.533,    0.0,
    };
    glUniformMatrix3fv(self.colorConversionMatrix_location, 1, GL_FALSE, colorConversion709);
    
    glUniform1i(self.samplerY_location, 0);
    glUniform1i(self.samplerUV_location, 1);
}

- (void)setupVariable
{
    self.position_location = glGetAttribLocation(self.program_id, "position");
    self.texture_coord_location = glGetAttribLocation(self.program_id, "textureCoord");
    self.matrix_location = glGetUniformLocation(self.program_id, "mpv_matrix");
    
    self.samplerY_location = glGetUniformLocation(self.program_id, "SamplerY");
    self.samplerUV_location = glGetUniformLocation(self.program_id, "SamplerUV");
    self.colorConversionMatrix_location = glGetUniformLocation(self.program_id, "colorConversionMatrix");
}

@end

