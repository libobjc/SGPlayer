//
//  SGDemuxerFunnel.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDemuxable.h"

@interface SGDemuxerFunnel : NSObject <SGDemuxable>

/**
 *
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithDemuxable:(id<SGDemuxable> _Nonnull)demuxable index:(int)index timeRange:(CMTimeRange)timeRange NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic, readonly) int index;

/**
 *
 */
@property (nonatomic, readonly) CMTimeRange timeRange;

/**
 *
 */
@property (nonatomic) BOOL overgop;

@end
