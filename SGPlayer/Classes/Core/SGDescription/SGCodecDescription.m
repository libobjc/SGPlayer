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
    SGCodecDescription *obj = [[SGCodecDescription alloc] init];
    [self fillToDescription:obj];
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_type = SGCodecType_Decode;
        self->_scale = CMTimeMake(1, 1);
        self->_timebase = AV_TIME_BASE_Q;
        self->_timeRange = CMTimeRangeMake(kCMTimeNegativeInfinity,
                                           kCMTimePositiveInfinity);
    }
    return self;
}

- (void)appendTimeLayout:(SGTimeLayout *)timeLayout
{
    NSMutableArray *timeLayouts = [NSMutableArray arrayWithArray:self->_timeLayouts];
    [timeLayouts addObject:timeLayout];
    CMTime scale = CMTimeMake(1, 1);
    for (SGTimeLayout *obj in timeLayouts) {
        scale = SGCMTimeMultiply(scale, obj.scale);
    }
    self->_scale = scale;
    self->_timeLayouts = timeLayouts;
    self->_timeRange = CMTimeRangeMake([timeLayout convertTimeStamp:self->_timeRange.start],
                                       [timeLayout convertDuration:self->_timeRange.duration]);
}

- (void)appendTimeRange:(CMTimeRange)timeRange
{
    for (SGTimeLayout *obj in self->_timeLayouts) {
        timeRange = CMTimeRangeMake([obj convertTimeStamp:timeRange.start],
                                    [obj convertDuration:timeRange.duration]);
    }
    self->_timeRange = CMTimeRangeGetIntersection(self->_timeRange, timeRange);
}

- (void)fillToDescription:(SGCodecDescription *)description
{
    description->_track = self->_track;
    description->_scale = self->_scale;
    description->_timebase = self->_timebase;
    description->_codecpar = self->_codecpar;
    description->_timeRange = self->_timeRange;
    description->_timeLayouts = [self->_timeLayouts copy];
}

- (BOOL)isEqualToDescription:(SGCodecDescription *)description
{
    if (![self isEqualCodecContextToDescription:description]) {
        return NO;
    }
    if (!CMTimeRangeEqual(description->_timeRange, self->_timeRange)) {
        return NO;
    }
    if (description->_timeLayouts.count != self->_timeLayouts.count) {
        return NO;
    }
    for (int i = 0; i < description->_timeLayouts.count; i++) {
        SGTimeLayout *t1 = [description->_timeLayouts objectAtIndex:i];
        SGTimeLayout *t2 = [self->_timeLayouts objectAtIndex:i];
        if (![t1 isEqualToTimeLayout:t2]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)isEqualCodecContextToDescription:(SGCodecDescription *)description
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
    return YES;
}

@end
