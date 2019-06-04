//
//  SGTrackDemuxer.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDemuxable.h"
#import "SGMutableTrack.h"

NS_ASSUME_NONNULL_BEGIN

@interface SGTrackDemuxer : NSObject <SGDemuxable>

/**
 *
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithTrack:(SGMutableTrack *)track;

@end

NS_ASSUME_NONNULL_END
