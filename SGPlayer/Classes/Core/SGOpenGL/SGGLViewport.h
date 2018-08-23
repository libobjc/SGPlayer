//
//  SGGLViewport.h
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGGLDefines.h"

typedef NS_ENUM(NSUInteger, SGGLViewportMode)
{
    SGGLViewportModeResize,
    SGGLViewportModeResizeAspect,
    SGGLViewportModeResizeAspectFill,
};

@interface SGGLViewport : NSObject

+ (void)updateWithLayerSize:(SGGLSize)layerSize scale:(double)scale;
+ (void)updateLeftWithLayerSize:(SGGLSize)layerSize scale:(double)scale;
+ (void)updateRightWithLayerSize:(SGGLSize)layerSize scale:(double)scale;
+ (void)updateWithMode:(SGGLViewportMode)mode textureSize:(SGGLSize)textureSize layerSize:(SGGLSize)layerSize scale:(double)scale;

@end
