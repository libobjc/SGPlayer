//
//  SGVideoDescriptor.h
//  SGPlayer
//
//  Created by Single on 2018/12/11.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGVideoDescriptor : NSObject <NSCopying>

/**
 *  AVPixelFormat
 */
@property (nonatomic) int format;

/**
 *  kCVPixelFormatType_XXX
 */
@property (nonatomic) OSType cv_format;

/**
 *
 */
@property (nonatomic) int width;

/**
 *
 */
@property (nonatomic) int height;

/**
 *  AVColorSpace
 */
@property (nonatomic) int colorspace;

/**
 *
 */
- (BOOL)isEqualToDescriptor:(SGVideoDescriptor *)descriptor;

@end
