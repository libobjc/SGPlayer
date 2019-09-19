//
//  SGURLSegment.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGURLSegment.h"
#import "SGSegment+Internal.h"
#import "SGExtractingDemuxer.h"
#import "SGURLDemuxer.h"
#import "SGTime.h"

@implementation SGURLSegment

- (id)copyWithZone:(NSZone *)zone
{
    SGURLSegment *obj = [super copyWithZone:zone];
    obj->_URL = [self->_URL copy];
    obj->_index = self->_index;
    obj->_timeRange = self->_timeRange;
    obj->_scale = self->_scale;
    return obj;
}

- (instancetype)initWithURL:(NSURL *)URL index:(NSInteger)index timeRange:(CMTimeRange)timeRange scale:(CMTime)scale
{
    scale = SGCMTimeValidate(scale, CMTimeMake(1, 1), NO);
    NSAssert(CMTimeCompare(scale, CMTimeMake(1, 10)) >= 0, @"Invalid Scale.");
    NSAssert(CMTimeCompare(scale, CMTimeMake(10, 1)) <= 0, @"Invalid Scale.");
    if (self = [super init]) {
        self->_URL = [URL copy];
        self->_index = index;
        self->_timeRange = timeRange;
        self->_scale = scale;
    }
    return self;
}

- (id<SGDemuxable>)newDemuxable
{
    SGURLDemuxer *demuxable = [[SGURLDemuxer alloc] initWithURL:self->_URL];
    SGExtractingDemuxer *obj = [[SGExtractingDemuxer alloc] initWithDemuxable:demuxable index:self->_index timeRange:self->_timeRange scale:self->_scale];
    return obj;
}

@end
