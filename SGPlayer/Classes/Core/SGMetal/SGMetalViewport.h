//
//  SGMetalViewport.h
//  SGPlayer
//
//  Created by Single on 2019/6/27.
//  Copyright © 2019 single. All rights reserved.
//

#import <Metal/Metal.h>

typedef NS_ENUM(int, SGMetalViewportMode) {
    SGMetalViewportModeResize,
    SGMetalViewportModeResizeAspect,
    SGMetalViewportModeResizeAspectFill,
};

@interface SGMetalViewport : NSObject

+ (MTLViewport)viewportWithLayerSize:(MTLSize)layerSize;
+ (MTLViewport)viewportWithLayerSizeForLeft:(MTLSize)layerSize;
+ (MTLViewport)viewportWithLayerSizeForRight:(MTLSize)layerSize;
+ (MTLViewport)viewportWithLayerSize:(MTLSize)layerSize textureSize:(MTLSize)textureSize mode:(SGMetalViewportMode)mode;


@end
