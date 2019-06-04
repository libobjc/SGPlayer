//
//  SGPaddingDemuxer.h
//  SGPlayer
//
//  Created by Single on 2019/6/4.
//  Copyright © 2019 single. All rights reserved.
//

#import "SGDemuxable.h"

NS_ASSUME_NONNULL_BEGIN

@interface SGPaddingDemuxer : NSObject <SGDemuxable>

/**
 *
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithDuration:(CMTime)duration;

@end

NS_ASSUME_NONNULL_END
