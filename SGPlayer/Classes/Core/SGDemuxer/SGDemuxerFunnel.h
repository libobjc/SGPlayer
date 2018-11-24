//
//  SGDemuxerFunnel.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDemuxable.h"

@interface SGDemuxerFunnel : NSObject <SGDemuxable>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDemuxable:(id<SGDemuxable>)demuxable;

@property (nonatomic, copy) NSArray<NSNumber *> *indexes;
@property (nonatomic) CMTimeRange timeRange;
@property (nonatomic) BOOL overgop;     // Default is YES.

@end
