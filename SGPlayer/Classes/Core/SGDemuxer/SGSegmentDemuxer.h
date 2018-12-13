//
//  SGSegmentDemuxer.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDemuxable.h"
#import "SGSegment.h"

@interface SGSegmentDemuxer : NSObject <SGDemuxable>

/**
 *
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithSegment:(SGSegment * _Nonnull)segment basetime:(CMTime)basetime NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic, strong, readonly) SGSegment * _Nonnull segment;

/**
 *
 */
@property (nonatomic, readonly) CMTime basetime;

@end
