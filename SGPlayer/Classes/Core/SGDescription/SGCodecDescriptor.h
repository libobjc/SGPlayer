//
//  SGCodecDescriptor.h
//  SGPlayer
//
//  Created by Single on 2018/11/15.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTimeLayout.h"
#import "SGFFmpeg.h"
#import "SGTrack.h"

typedef NS_ENUM(NSUInteger, SGCodecType) {
    SGCodecTypeDecode  = 0,
    SGCodecTypePadding = 1,
};

@interface SGCodecDescriptor : NSObject <NSCopying>

/**
 *
 */
@property (nonatomic) SGCodecType type;

/**
 *
 */
@property (nonatomic) AVRational timebase;

/**
 *
 */
@property (nonatomic) AVCodecParameters *codecpar;

/**
 *
 */
@property (nonatomic, strong) SGTrack *track;

/**
 *
 */
@property (nonatomic, strong) NSDictionary *metadata;

/**
 *
 */
@property (nonatomic, readonly) CMTimeRange timeRange;

/**
 *
 */
@property (nonatomic, readonly) CMTime scale;

/**
 *
 */
- (CMTime)convertTimeStamp:(CMTime)timeStamp;

/**
 *
 */
- (CMTime)convertDuration:(CMTime)duration;

/**
 *
 */
- (void)appendTimeRange:(CMTimeRange)timeRange;

/**
 *
 */
- (void)appendTimeLayout:(SGTimeLayout *)timeLayout;

/**
 *
 */
- (void)fillToDescriptor:(SGCodecDescriptor *)descriptor;

/**
 *
 */
- (BOOL)isEqualToDescriptor:(SGCodecDescriptor *)descriptor;

/**
 *
 */
- (BOOL)isEqualCodecContextToDescriptor:(SGCodecDescriptor *)descriptor;

@end
