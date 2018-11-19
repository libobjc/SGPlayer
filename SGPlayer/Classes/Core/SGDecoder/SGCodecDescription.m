//
//  SGCodecDescription.m
//  SGPlayer
//
//  Created by Single on 2018/11/15.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGCodecDescription.h"

@implementation SGCodecDescription

- (id)copyWithZone:(NSZone *)zone
{
    SGCodecDescription * obj = [[SGCodecDescription alloc] init];
    obj->_track = self->_track;
    obj->_timebase = self->_timebase;
    obj->_codecpar = self->_codecpar;
    obj->_timeRange = self->_timeRange;
    obj->_timeLayouts = [self->_timeLayouts copy];
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_timebase = av_make_q(0, 1);
        self->_timeRange = CMTimeRangeMake(kCMTimeNegativeInfinity, kCMTimePositiveInfinity);
    }
    return self;
}

- (BOOL)isEqualToDescription:(SGCodecDescription *)description
{
    if (!description) {
        return NO;
    }
    if (description.track != self->_track) {
        return NO;
    }
    if (description->_codecpar != self->_codecpar) {
        return NO;
    }
    if (av_cmp_q(description->_timebase, self->_timebase) != 0) {
        return NO;
    }
    if (!CMTimeRangeEqual(description->_timeRange, self->_timeRange)) {
        return NO;
    }
    if (description->_timeLayouts.count != self->_timeLayouts.count) {
        return NO;
    }
    for (int i = 0; i < description->_timeLayouts.count; i++) {
        SGTimeLayout * t1 = [description->_timeLayouts objectAtIndex:i];
        SGTimeLayout * t2 = [self->_timeLayouts objectAtIndex:i];
        if (![t1 isEqualToTimeLayout:t2]) {
            return NO;
        }
    }
    return YES;
}

- (void)appendTimeLayout:(SGTimeLayout *)timeLayout
{
    NSMutableArray * ret = [NSMutableArray arrayWithArray:self->_timeLayouts];
    [ret addObject:timeLayout];
    self->_timeLayouts = ret;
}

- (void)appendTimeRange:(CMTimeRange)timeRange
{
    self->_timeRange = CMTimeRangeGetIntersection(self->_timeRange, timeRange);
}

- (CMTimeRange)layoutTimeRange
{
    CMTimeRange timeRange = self->_timeRange;
    for (SGTimeLayout * obj in self->_timeLayouts) {
        timeRange = CMTimeRangeMake([obj convertTimeStamp:timeRange.start],
                                    [obj convertDuration:timeRange.duration]);
    }
    return timeRange;
}

@end
