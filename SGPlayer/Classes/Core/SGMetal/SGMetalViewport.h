//
//  SGMetalViewport.h
//  SGPlayer
//
//  Created by Single on 2019/6/27.
//  Copyright © 2019 single. All rights reserved.
//

#import <Metal/Metal.h>

typedef NS_ENUM(NSUInteger, SGMetalViewportMode) {
    SGMetalViewportModeResize           = 0,
    SGMetalViewportModeResizeAspect     = 1,
    SGMetalViewportModeResizeAspectFill = 2,
};

@interface SGMetalViewport : NSObject

+ (MTLViewport)viewportWithLayerSize:(MTLSize)layerSize;
+ (MTLViewport)viewportWithLayerSizeForLeft:(MTLSize)layerSize;
+ (MTLViewport)viewportWithLayerSizeForRight:(MTLSize)layerSize;
+ (MTLViewport)viewportWithLayerSize:(MTLSize)layerSize textureSize:(MTLSize)textureSize mode:(SGMetalViewportMode)mode;


@end
