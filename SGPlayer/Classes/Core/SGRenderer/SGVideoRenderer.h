//
//  SGVideoRenderer.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGVideoFrame.h"
#import "SGVRViewport.h"
#import "SGPLFImage.h"
#import "SGPLFView.h"

typedef NS_ENUM(NSUInteger, SGDisplayMode) {
    SGDisplayModePlane = 0,
    SGDisplayModeVR    = 1,
    SGDisplayModeVRBox = 2,
};

typedef NS_ENUM(NSUInteger, SGScalingMode) {
    SGScalingModeResize           = 0,
    SGScalingModeResizeAspect     = 1,
    SGScalingModeResizeAspectFill = 2,
};

@interface SGVideoRenderer : NSObject

/**
 *  Main thread only.
 */
@property (nonatomic, strong) SGPLFView *view;

/**
 *  Main thread only.
 */
@property (nonatomic, strong, readonly) SGVRViewport *viewport;

/**
 *  Main thread only.
 */
@property (nonatomic, copy) void (^frameOutput)(SGVideoFrame *frame);

/**
 *  Main thread only.
 */
@property (nonatomic) NSInteger preferredFramesPerSecond;

/**
 *  Main thread only.
 */
@property (nonatomic) SGScalingMode scalingMode;

/**
 *  Main thread only.
 */
@property (nonatomic) SGDisplayMode displayMode;

/**
 *  Main thread only.
 */
- (SGPLFImage *)currentImage;

@end
