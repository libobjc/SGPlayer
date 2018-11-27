//
//  SGURLSegment.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGURLSegment.h"
#import "SGSegment+Internal.h"
#import "SGDemuxerFunnel.h"
#import "SGURLDemuxer.h"

@implementation SGURLSegment

- (id)copyWithZone:(NSZone *)zone
{
    SGURLSegment * obj = [super copyWithZone:zone];
    obj.URL = self.URL;
    obj.index = self.index;
    return obj;
}

- (instancetype)initWithURL:(NSURL *)URL index:(int32_t)index
{
    return [self initWithURL:URL index:index timeRange:kCMTimeRangeInvalid scale:kCMTimeInvalid];
}

- (instancetype)initWithURL:(NSURL *)URL index:(int32_t)index timeRange:(CMTimeRange)timeRange scale:(CMTime)scale
{
    if (self = [super initWithTimeRange:timeRange scale:scale]) {
        self.URL = URL;
        self.index = index;
    }
    return self;
}

- (id<SGDemuxable>)newDemuxable
{
    SGURLDemuxer * demuxable = [[SGURLDemuxer alloc] initWithURL:self.URL];
    SGDemuxerFunnel * obj = [[SGDemuxerFunnel alloc] initWithDemuxable:demuxable];
    obj.timeRange = self.timeRange;
    obj.indexes = @[@(self.index)];
    return obj;
}

@end
