//
//  SGSegment.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface SGSegment : NSObject <NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/*!
 @property timeRange
 @abstract
    Indicates the timeRange of the segment.
 */
@property (nonatomic, readonly) CMTimeRange timeRange;

/*!
 @property scale
 @abstract
    Indicates the scale of the segment.
 */
@property (nonatomic, readonly) CMTime scale;

@end
