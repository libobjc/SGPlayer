//
//  SGSegment.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSegment.h"
#import "SGSegment+Internal.h"

@implementation SGSegment

- (id)copyWithZone:(NSZone *)zone
{
    SGSegment *obj = [[self.class alloc] init];
    obj->_timeRange = self->_timeRange;
    obj->_scale = self->_scale;
    return obj;
}

- (instancetype)initWithTimeRange:(CMTimeRange)timeRange scale:(CMTime)scale
{
    if (self = [super init]) {
        self->_timeRange = timeRange;
        self->_scale = scale;
    }
    return self;
}

- (id<SGDemuxable>)newDemuxable
{
    return nil;
}

@end
