//
//  SGSegment.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSegment.h"
#import "SGSegment+Internal.h"
#import "SGPaddingSegment.h"
#import "SGURLSegment.h"

@implementation SGSegment

+ (instancetype)segmentWithDuration:(CMTime)duration
{
    return [[SGPaddingSegment alloc] initWithDuration:duration];
}

+ (instancetype)segmentWithURL:(NSURL *)URL index:(NSInteger)index
{
    return [[SGURLSegment alloc] initWithURL:URL index:index timeRange:kCMTimeRangeInvalid scale:kCMTimeInvalid];
}

+ (instancetype)segmentWithURL:(NSURL *)URL index:(NSInteger)index timeRange:(CMTimeRange)timeRange scale:(CMTime)scale
{
    return [[SGURLSegment alloc] initWithURL:URL index:index timeRange:timeRange scale:scale];
}

- (id)copyWithZone:(NSZone *)zone
{
    SGSegment *obj = [[self.class alloc] init];
    return obj;
}

- (id<SGDemuxable>)newDemuxable
{
    NSAssert(NO, @"Subclass only.");
    return nil;
}

@end
