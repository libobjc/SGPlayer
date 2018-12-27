//
//  SGMutilDemuxer.h
//  SGPlayer
//
//  Created by Single on 2018/11/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDemuxable.h"

NS_ASSUME_NONNULL_BEGIN

@interface SGMutilDemuxer : NSObject <SGDemuxable>

/**
 *
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithDemuxables:(NSArray<id<SGDemuxable>> *)demuxables NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
