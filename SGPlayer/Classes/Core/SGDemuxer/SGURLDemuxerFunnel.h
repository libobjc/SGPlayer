//
//  SGURLDemuxerFunnel.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDemuxable.h"

@interface SGURLDemuxerFunnel : NSObject <SGDemuxable>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic) CMTimeRange timeRange;
@property (nonatomic, strong) NSArray <NSNumber *> * indexes;

@property (nonatomic) BOOL overgop;     // Default is YES.

@end
