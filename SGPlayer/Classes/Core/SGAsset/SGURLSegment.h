//
//  SGURLSegment.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSegment.h"

@interface SGURLSegment : SGSegment

/**
 *
 */
- (instancetype)initWithTimeRange:(CMTimeRange)timeRange scale:(CMTime)scale NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithURL:(NSURL * _Nonnull)URL index:(int)index timeRange:(CMTimeRange)timeRange scale:(CMTime)scale NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic, copy, readonly) NSURL * _Nonnull URL;

/**
 *
 */
@property (nonatomic, readonly) int index;

@end
