//
//  SGPaddingSegment.m
//  SGPlayer
//
//  Created by Single on 2019/9/19.
//  Copyright © 2019 single. All rights reserved.
//

#import "SGPaddingSegment.h"
#import "SGSegment+Internal.h"
#import "SGPaddingDemuxer.h"

@implementation SGPaddingSegment

- (id)copyWithZone:(NSZone *)zone
{
    SGPaddingSegment *obj = [super copyWithZone:zone];
    obj->_duration = self->_duration;
    return obj;
}

- (instancetype)initWithDuration:(CMTime)duration
{
    if (self = [super init]) {
        self->_duration = duration;
    }
    return self;
}

- (id<SGDemuxable>)newDemuxable
{
    return [[SGPaddingDemuxer alloc] initWithDuration:self->_duration];
}

@end
