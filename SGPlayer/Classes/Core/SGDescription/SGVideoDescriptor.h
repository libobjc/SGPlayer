//
//  SGVideoDescriptor.h
//  SGPlayer
//
//  Created by Single on 2018/12/11.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDefines.h"

@interface SGVideoDescriptor : NSObject <NSCopying>

/*!
 @property format
 @abstract
    Indicates the vdieo format.
 
 @discussion
    The value corresponds to AVPixelFormat.
 */
@property (nonatomic) int format;

/*!
 @property cv_format
 @abstract
    Indicates the vdieo format.
 
 @discussion
    The value corresponds to kCVPixelFormatType_XXX.
 */
@property (nonatomic) OSType cv_format;

/*!
 @property width
 @abstract
    Indicates the width.
 */
@property (nonatomic) int width;

/*!
 @property height
 @abstract
    Indicates the height.
 */
@property (nonatomic) int height;

/*!
 @property sampleAspectRatio
 @abstract
    Indicates the sample aspect ratio, 0/1 if unknown/unspecified.
*/
@property (nonatomic) SGRational sampleAspectRatio;

/*!
 @property frameSize
 @abstract
    Indicates the pixel buffer frame size.
*/
@property (nonatomic, readonly) SGRational frameSize;

/*!
 @property presentationSize
 @abstract
    Indicates the best presentation size.
*/
@property (nonatomic, readonly) SGRational presentationSize;

/*!
 @method numberOfPlanes
 @abstract
    Get the number of planes.
 */
- (int)numberOfPlanes;

/*!
 @method isEqualToDescriptor:
 @abstract
    Check if the descriptor is equal to another.
 */
- (BOOL)isEqualToDescriptor:(SGVideoDescriptor *)descriptor;

@end
