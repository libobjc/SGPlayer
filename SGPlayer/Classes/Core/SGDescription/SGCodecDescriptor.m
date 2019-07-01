//
//  SGCodecDescriptor.m
//  SGPlayer
//
//  Created by Single on 2018/11/15.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGCodecDescriptor.h"

@implementation SGCodecDescriptor

- (id)copyWithZone:(NSZone *)zone
{
    SGCodecDescriptor *obj = [[SGCodecDescriptor alloc] init];
    [self fillToDescriptor:obj];
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_type = SGCodecTypeDecode;
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
    self->_timeRange = SGCMTimeRangeGetIntersection(self->_timeRange, timeRange);
}

- (void)fillToDescriptor:(SGCodecDescriptor *)descriptor
{
    descriptor->_track = self->_track;
    descriptor->_scale = self->_scale;
    descriptor->_timebase = self->_timebase;
    descriptor->_codecpar = self->_codecpar;
    descriptor->_timeRange = self->_timeRange;
    descriptor->_timeLayouts = [self->_timeLayouts copy];
}

- (BOOL)isEqualToDescriptor:(SGCodecDescriptor *)descriptor
{
    if (![self isEqualCodecContextToDescriptor:descriptor]) {
        return NO;
    }
    if (!CMTimeRangeEqual(descriptor->_timeRange, self->_timeRange)) {
        return NO;
    }
    if (descriptor->_timeLayouts.count != self->_timeLayouts.count) {
        return NO;
    }
    for (int i = 0; i < descriptor->_timeLayouts.count; i++) {
        SGTimeLayout *t1 = [descriptor->_timeLayouts objectAtIndex:i];
        SGTimeLayout *t2 = [self->_timeLayouts objectAtIndex:i];
        if (![t1 isEqualToTimeLayout:t2]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)isEqualCodecContextToDescriptor:(SGCodecDescriptor *)descriptor
{
    if (!descriptor) {
        return NO;
    }
    if (descriptor.track != self->_track) {
        return NO;
    }
    if (descriptor->_codecpar != self->_codecpar) {
        return NO;
    }
    if (av_cmp_q(descriptor->_timebase, self->_timebase) != 0) {
        return NO;
    }
    return YES;
}

@end
