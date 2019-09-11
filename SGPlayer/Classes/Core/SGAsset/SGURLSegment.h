//
//  SGURLSegment.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSegment.h"

@interface SGURLSegment : SGSegment

/*!
 @method initWithURL:index:
 @abstract
    Equivalent:
        [self initWithURL:URL index:index timeRange:kCMTimeRangeInvalid scale:kCMTimeInvalid];
 */
- (instancetype)initWithURL:(NSURL *)URL index:(NSInteger)index;

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

@end
