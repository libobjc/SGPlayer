//
//  SGGLViewport.m
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLViewport.h"
#import "SGPLFOpenGL.h"

@implementation SGGLViewport

+ (void)updateWithLayerSize:(SGGLSize)layerSize scale:(double)scale textureSize:(SGGLSize)textureSize mode:(SGGLViewportMode)mode
{
    SGGLRect viewport = {0, 0, layerSize.width, layerSize.height};
    switch (mode)
    {
        case SGGLViewportModeResize:
            break;
        case SGGLViewportModeResizeAspect:
        {
            double layerAspect = (double)layerSize.width / layerSize.height;
            double textureAspect = (double)textureSize.width / textureSize.height;
            if (fabs(layerAspect - textureAspect) <= 0.0001)
            {
                
            }
            else if (layerAspect < textureAspect)
            {
                double height = layerSize.width / textureAspect;
                viewport.x = 0;
                viewport.y = (layerSize.height - height) / 2;
                viewport.width = layerSize.width;
                viewport.height = height;
            }
            else if (layerAspect > textureAspect)
            {
                double width = layerSize.height * textureAspect;
                viewport.x = (layerSize.width - width) / 2;
                viewport.y = 0;
                viewport.width = width;
                viewport.height = layerSize.height;
            }
        }
            break;
        case SGGLViewportModeResizeAspectFill:
        {
            double layerAspect = (double)layerSize.width / layerSize.height;
            double textureAspect = (double)textureSize.width / textureSize.height;
            if (fabs(layerAspect - textureAspect) <= 0.0001)
            {
                
            }
            else if (layerAspect < textureAspect)
            {
                double width = layerSize.height * textureAspect;
                viewport.x = (layerSize.width - width) / 2;
                viewport.y = 0;
                viewport.width = width;
                viewport.height = layerSize.height;
            }
            else if (layerAspect > textureAspect)
            {
                double height = layerSize.width / textureAspect;
                viewport.x = 0;
                viewport.y = (layerSize.height - height) / 2;
                viewport.width = layerSize.width;
                viewport.height = height;
            }
        }
            break;
    }
    glViewport(viewport.x * scale, viewport.y * scale, viewport.width * scale, viewport.height * scale);
}

+ (void)updateWithLayerSize:(SGGLSize)layerSize scale:(double)scale
{
    SGGLRect viewport = {0, 0, layerSize.width, layerSize.height};
    glViewport(viewport.x * scale, viewport.y * scale, viewport.width * scale, viewport.height * scale);
}

+ (void)updateWithLayerSizeForLeft:(SGGLSize)layerSize scale:(double)scale
{
    SGGLRect viewport = {0, 0, layerSize.width / 2, layerSize.height};
    glViewport(viewport.x * scale, viewport.y * scale, viewport.width * scale, viewport.height * scale);
}

+ (void)updateWithLayerSizeForRight:(SGGLSize)layerSize scale:(double)scale
{
    SGGLRect viewport = {layerSize.width / 2, 0, layerSize.width / 2, layerSize.height};
    glViewport(viewport.x * scale, viewport.y * scale, viewport.width * scale, viewport.height * scale);
}

@end
