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

+ (void)updateViewport:(SGGLSize)renderSize
           displaySize:(SGGLSize)displaySize
                  mode:(SGGLViewportMode)mode
{
    SGGLRect viewport = {0, 0, displaySize.width, displaySize.height};
    double renderAspect = (double)renderSize.width / renderSize.height;
    double displayAspect = (double)displaySize.width / displaySize.height;
    if (fabs(displayAspect - renderAspect) <= 0.0001)
    {
        
    }
    else if (displayAspect < renderAspect)
    {
        double height = displaySize.width / renderAspect;
        viewport.x = 0;
        viewport.y = (displaySize.height - height) / 2;
        viewport.width = displaySize.width;
        viewport.height = height;
    }
    else if (displayAspect > renderAspect)
    {
        double width = displaySize.height * renderAspect;
        viewport.x = (displaySize.width - width) / 2;
        viewport.y = 0;
        viewport.width = width;
        viewport.height = displaySize.height;
    }
    glViewport(viewport.x, viewport.y, viewport.width, viewport.height);
}

@end
