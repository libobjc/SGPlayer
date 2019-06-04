//
//  SGSegmentDemuxer.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDemuxable.h"
#import "SGSegment.h"

NS_ASSUME_NONNULL_BEGIN

@interface SGSegmentDemuxer : NSObject <SGDemuxable>

/**
 *
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithSegment:(SGSegment *)segment basetime:(CMTime)basetime;

/**
 *
 */
@property (nonatomic, strong, readonly) SGSegment *segment;

/**
 *
 */
@property (nonatomic, readonly) CMTime basetime;

@end

NS_ASSUME_NONNULL_END
