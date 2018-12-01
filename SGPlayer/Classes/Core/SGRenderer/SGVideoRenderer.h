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

typedef NS_ENUM(int, SGDisplayMode) {
    SGDisplayModePlane,
    SGDisplayModeVR,
    SGDisplayModeVRBox,
};

typedef NS_ENUM(int, SGScalingMode) {
    SGScalingModeResize,
    SGScalingModeResizeAspect,
    SGScalingModeResizeAspectFill,
};

@interface SGVideoRenderer : NSObject

/**
 *  Main thread only.
 */
@property (nonatomic, strong) SGPLFView * view;

/**
 *  Main thread only.
 */
@property (nonatomic, strong) SGVRViewport * viewport;

/**
 *  Main thread only.
 */
@property (nonatomic, copy) void (^frameOutput)(SGVideoFrame * frame);

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
@property (nonatomic) CMTime displayInterval;

/**
 *  Main thread only.
 */
- (SGPLFImage *)originalImage;

/**
 *  Main thread only.
 */
- (SGPLFImage *)snapshot;

@end
