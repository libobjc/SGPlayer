//
//  SGMutilDemuxer.h
//  SGPlayer
//
//  Created by Single on 2018/11/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDemuxable.h"

@interface SGMutilDemuxer : NSObject <SGDemuxable>

- (instancetype)initWithDemuxables:(NSArray <id <SGDemuxable>> *)demuxables;

@end
