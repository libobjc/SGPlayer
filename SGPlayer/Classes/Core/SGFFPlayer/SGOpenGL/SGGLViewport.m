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

+ (void)updateWithMode:(SGGLViewportMode)mode textureSize:(SGGLSize)textureSize layerSize:(SGGLSize)layerSize
{
    SGGLRect viewport = {0, 0, layerSize.width, layerSize.height};
    double renderAspect = (double)textureSize.width / textureSize.height;
    double displayAspect = (double)layerSize.width / layerSize.height;
    if (fabs(displayAspect - renderAspect) <= 0.0001)
    {
        
    }
    else if (displayAspect < renderAspect)
    {
        double height = layerSize.width / renderAspect;
        viewport.x = 0;
        viewport.y = (layerSize.height - height) / 2;
        viewport.width = layerSize.width;
        viewport.height = height;
    }
    else if (displayAspect > renderAspect)
    {
        double width = layerSize.height * renderAspect;
        viewport.x = (layerSize.width - width) / 2;
        viewport.y = 0;
        viewport.width = width;
        viewport.height = layerSize.height;
    }
    glViewport(viewport.x, viewport.y, viewport.width, viewport.height);
}

@end
