//
//  SGURLDemuxerFunnel.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDemuxable.h"

@interface SGURLDemuxerFunnel : NSObject <SGDemuxable>

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic) CMTimeRange desireTimeRange;
@property (nonatomic, strong) NSArray <NSNumber *> * desireIndexes;

@end
