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

/*!
 @method supportedPixelFormats
 @abstract
    Indicates all supported pixel formats.
*/
+ (NSArray<NSNumber *> *)supportedPixelFormats;

/*!
 @method isSupportedInputFormat:
 @abstract
    Indicates whether the input format is supported.
*/
+ (BOOL)isSupportedInputFormat:(int)format;

/*!
 @property view
 @abstract
    Indicates the view that displays content.
 
 @discussion
    Main thread only.
 */
@property (nonatomic, strong) SGPLFView *view;

/*!
 @property viewport
 @abstract
    Indicates the current vr viewport.
 
 @discussion
    Main thread only.
 */
@property (nonatomic, strong, readonly) SGVRViewport *viewport;

/*!
 @property frameOutput
 @abstract
    Capture the video frame that will be rendered.
 
 @discussion
    Main thread only.
 */
@property (nonatomic, copy) void (^frameOutput)(SGVideoFrame *frame);

/*!
 @property preferredFramesPerSecond
 @abstract
    Indicates how many frames are rendered in one second.
    Default is 30.
 
 @discussion
    Main thread only.
 */
@property (nonatomic) NSInteger preferredFramesPerSecond;

/*!
 @property scalingMode
 @abstract
    Indicates current scaling mode.
 
 @discussion
    Main thread only.
 */
@property (nonatomic) SGScalingMode scalingMode;

/*!
 @property displayMode
 @abstract
    Indicates current display mode.
 
 @discussion
    Main thread only.
 */
@property (nonatomic) SGDisplayMode displayMode;

/*!
 @method currentImage
 @abstract
    Generate a screenshot of the current view.
 
 @discussion
    Main thread only.
 */
- (SGPLFImage *)currentImage;

@end
