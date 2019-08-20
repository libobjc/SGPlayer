//
//  SGPaddingSegment.m
//  SGPlayer
//
//  Created by Single on 2019/6/4.
//  Copyright © 2019 single. All rights reserved.
//

#import "SGPaddingSegment.h"
#import "SGSegment+Internal.h"
#import "SGPaddingDemuxer.h"

@implementation SGPaddingSegment

- (id)copyWithZone:(NSZone *)zone
{
    SGPaddingSegment *obj = [super copyWithZone:zone];
    return obj;
}

- (instancetype)initWithDuration:(CMTime)duration
{
    if (self = [super initWithTimeRange:CMTimeRangeMake(kCMTimeZero, duration) scale:kCMTimeInvalid]) {
        
    }
    return self;
}

- (id<SGDemuxable>)newDemuxable
{
    return [[SGPaddingDemuxer alloc] initWithDuration:self.timeRange.duration];
}

@end
