//
//  SGURLSegment.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSegment.h"

@interface SGURLSegment : SGSegment

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method initWithURL:index:timeRange:scale:
 @abstract
    Initializes an SGURLSegment.
 */
- (instancetype)initWithURL:(NSURL *)URL index:(NSInteger)index timeRange:(CMTimeRange)timeRange scale:(CMTime)scale;

/*!
 @property URL
 @abstract
    Indicates the URL of the segment.
 */
@property (nonatomic, copy, readonly) NSURL *URL;

/*!
 @property type
 @abstract
    Indicates the index.
 */
@property (nonatomic, readonly) NSInteger index;

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
