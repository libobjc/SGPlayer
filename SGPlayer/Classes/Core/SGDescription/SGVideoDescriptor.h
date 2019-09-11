//
//  SGVideoDescriptor.h
//  SGPlayer
//
//  Created by Single on 2018/12/11.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

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
 @property colorspace
 @abstract
    Indicates the colorspace.
 
 @discussion
    The value corresponds to AVColorSpace.
 */
@property (nonatomic) int colorspace;

/*!
 @method isEqualToDescriptor:
 @abstract
    Check if the descriptor is equal to another.
 */
- (BOOL)isEqualToDescriptor:(SGVideoDescriptor *)descriptor;

@end
