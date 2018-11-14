//
//  SGConcatDemuxer.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDemuxable.h"
#import "SGConcatDemuxerUnit.h"

@interface SGConcatDemuxer : NSObject <SGDemuxable>

- (instancetype)initWithUnits:(NSArray <SGConcatDemuxerUnit *> *)units;

@end
