//
//  SGDecoderOptions.h
//  SGPlayer
//
//  Created by Single on 2019/6/14.
//  Copyright © 2019 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGDecoderOptions : NSObject <NSCopying>

/**
 *
 */
@property (nonatomic, copy) NSDictionary *options;

/**
 *
 */
@property (nonatomic) BOOL threadsAuto;

/**
 *
 */
@property (nonatomic) BOOL refcountedFrames;

/**
 *
 */
@property (nonatomic) BOOL hardwareDecodeH264;

/**
 *
 */
@property (nonatomic) BOOL hardwareDecodeH265;

/**
 *
 */
@property (nonatomic) OSType preferredPixelFormat;

@end
