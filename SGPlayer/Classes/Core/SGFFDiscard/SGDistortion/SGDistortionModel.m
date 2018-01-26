//
//  SGDistortionModel.m
//  DistortionDemo
//
//  Created by Single on 26/12/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import "SGDistortionModel.h"

@implementation SGDistortionModel

+ (instancetype)modelWithModelType:(SGDistortionModelType)modelType
{
    return [[self alloc] initWithModelType:modelType];
}

- (instancetype)initWithModelType:(SGDistortionModelType)modelType
{
    if (self = [super init]) {
        _modelType = modelType;
        [self setupBufferData];
    }
    return self;
}

- (void)setupBufferData
{
    float xEyeOffsetScreen = 0.523064613;
    float yEyeOffsetScreen = 0.80952388;
    
    float viewportWidthTexture = 1.43138313;
    float viewportHeightTexture = 1.51814604;
    
    float viewportXTexture = 0;
    float viewportYTexture = 0;
    
    float textureWidth = 2.86276627;
    float textureHeight = 1.51814604;
    
    float xEyeOffsetTexture = 0.592283607;
    float yEyeOffsetTexture = 0.839099586;
    
    float screenWidth = 2.47470069;
    float screenHeight = 1.39132345;
    
    switch (self.modelType) {
        case SGDistortionModelTypeLeft:
            break;
        case SGDistortionModelTypeRight:
            xEyeOffsetScreen = 1.95163608;
            viewportXTexture = 1.43138313;
            xEyeOffsetTexture = 2.27048278;
            break;
    }
    
    GLfloat vertexData[14400];
    
    int vertexOffset = 0;
    
    const int rows = 40;
    const int cols = 40;
    
    const float vignetteSizeTanAngle = 0.05f;
    
    for (int row = 0; row < rows; row++)
    {
        for (int col = 0; col < cols; col++)
        {
            const float uTextureBlue = col / 39.0f * (viewportWidthTexture / textureWidth) + viewportXTexture / textureWidth;
            const float vTextureBlue = row / 39.0f * (viewportHeightTexture / textureHeight) + viewportYTexture / textureHeight;
            
            const float xTexture = uTextureBlue * textureWidth - xEyeOffsetTexture;
            const float yTexture = vTextureBlue * textureHeight - yEyeOffsetTexture;
            const float rTexture = sqrtf(xTexture * xTexture + yTexture * yTexture);
            
            const float textureToScreenBlue = (rTexture > 0.0f) ? [self blueDistortInverse:rTexture] / rTexture : 1.0f;
            
            const float xScreen = xTexture * textureToScreenBlue;
            const float yScreen = yTexture * textureToScreenBlue;
            
            const float uScreen = (xScreen + xEyeOffsetScreen) / screenWidth;
            const float vScreen = (yScreen + yEyeOffsetScreen) / screenHeight;
            const float rScreen = rTexture * textureToScreenBlue;
            
            const float screenToTextureGreen = (rScreen > 0.0f) ? [self distortionFactor:rScreen] : 1.0f;
            const float uTextureGreen = (xScreen * screenToTextureGreen + xEyeOffsetTexture) / textureWidth;
            const float vTextureGreen = (yScreen * screenToTextureGreen + yEyeOffsetTexture) / textureHeight;
            
            const float screenToTextureRed = (rScreen > 0.0f) ? [self distortionFactor:rScreen] : 1.0f;
            const float uTextureRed = (xScreen * screenToTextureRed + xEyeOffsetTexture) / textureWidth;
            const float vTextureRed = (yScreen * screenToTextureRed + yEyeOffsetTexture) / textureHeight;
            
            const float vignetteSizeTexture = vignetteSizeTanAngle / textureToScreenBlue;
            
            const float dxTexture = xTexture + xEyeOffsetTexture - clamp(xTexture + xEyeOffsetTexture,
                                                                         viewportXTexture + vignetteSizeTexture,
                                                                         viewportXTexture + viewportWidthTexture - vignetteSizeTexture);
            const float dyTexture = yTexture + yEyeOffsetTexture - clamp(yTexture + yEyeOffsetTexture,
                                                                         viewportYTexture + vignetteSizeTexture,
                                                                         viewportYTexture + viewportHeightTexture - vignetteSizeTexture);
            const float drTexture = sqrtf(dxTexture * dxTexture + dyTexture * dyTexture);
            
            float vignette = 1.0f;
            
            bool vignetteEnabled = true;
            if (vignetteEnabled)
            {
                vignette = 1.0f - clamp(drTexture / vignetteSizeTexture, 0.0f, 1.0f);
            }
            
            vertexData[(vertexOffset + 0)] = 2.0f * uScreen - 1.0f;
            vertexData[(vertexOffset + 1)] = 2.0f * vScreen - 1.0f;
            vertexData[(vertexOffset + 2)] = vignette;
            vertexData[(vertexOffset + 3)] = uTextureRed;
            vertexData[(vertexOffset + 4)] = vTextureRed;
            vertexData[(vertexOffset + 5)] = uTextureGreen;
            vertexData[(vertexOffset + 6)] = vTextureGreen;
            vertexData[(vertexOffset + 7)] = uTextureBlue;
            vertexData[(vertexOffset + 8)] = vTextureBlue;
            
            vertexOffset += 9;
        }
    }
    
    self.index_count = 3158;
    GLshort indexData[self.index_count];
    
    int indexOffset = 0;
    vertexOffset = 0;
    for (int row = 0; row < rows-1; row++)
    {
        if (row > 0)
        {
            indexData[indexOffset] = indexData[(indexOffset - 1)];
            indexOffset++;
        }
        for (int col = 0; col < cols; col++)
        {
            if (col > 0)
            {
                if (row % 2 == 0)
                {
                    vertexOffset++;
                }
                else
                {
                    vertexOffset--;
                }
            }
            indexData[(indexOffset++)] = vertexOffset;
            indexData[(indexOffset++)] = (vertexOffset + 40);
        }
        vertexOffset += 40;
    }
    
    GLuint bufferIDs[2] = { 0, 0 };
    glGenBuffers(2, bufferIDs);
    self.vertex_buffer_id = bufferIDs[0];
    self.index_buffer_id = bufferIDs[1];
    
    glBindBuffer(GL_ARRAY_BUFFER, self.vertex_buffer_id);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.index_buffer_id);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexData), indexData, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

- (float)blueDistortInverse:(float)radius
{
    float r0 = radius / 0.9f;
    float r = radius * 0.9f;
    float dr0 = radius - [self distort:r0];
    while (fabsf(r - r0) > 0.0001f)
    {
        float dr = radius - [self distort:r];
        float r2 = r - dr * ((r - r0) / (dr - dr0));
        r0 = r;
        r = r2;
        dr0 = dr;
    }
    return r;
}

- (float)distort:(float)radius
{
    return radius * [self distortionFactor:radius];
}

- (float)distortionFactor:(float)radius
{
    int s_numberOfCoefficients = 2;
    static float _coefficients[2] = {0.441000015, 0.156000003};
    
    float result = 1.0f;
    float rFactor = 1.0f;
    float squaredRadius = radius * radius;
    for (int i = 0; i < s_numberOfCoefficients; i++)
    {
        rFactor *= squaredRadius;
        result += _coefficients[i] * rFactor;
    }
    return result;
}

float clamp(float val, float min, float max)
{
    return MAX(min, MIN(max, val));
}

@end
