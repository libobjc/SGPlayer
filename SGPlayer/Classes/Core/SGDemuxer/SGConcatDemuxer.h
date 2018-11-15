//
//  SGConcatDemuxer.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDemuxable.h"
#import "SGSegment.h"

@interface SGConcatDemuxer : NSObject <SGDemuxable>

- (instancetype)initWithType:(SGMediaType)type index:(int32_t)index segments:(NSArray <SGSegment *> *)segments;

@end
