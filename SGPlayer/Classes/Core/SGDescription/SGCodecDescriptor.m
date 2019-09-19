//
//  SGCodecDescriptor.m
//  SGPlayer
//
//  Created by Single on 2018/11/15.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGCodecDescriptor.h"

@interface SGCodecDescriptor ()

@property (nonatomic, copy, readonly) NSArray<SGTimeLayout *> *timeLayouts;

@end

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
        self->_timeRange = CMTimeRangeMake(kCMTimeNegativeInfinity, kCMTimePositiveInfinity);
    }
    return self;
}

- (void)appendTimeLayout:(SGTimeLayout *)timeLayout
{
    NSMutableArray *timeLayouts = [NSMutableArray arrayWithArray:self->_timeLayouts];
    [timeLayouts addObject:timeLayout];
    CMTime scale = CMTimeMake(1, 1);
    for (SGTimeLayout *obj in timeLayouts) {
        if (CMTIME_IS_NUMERIC(obj.scale)) {
            scale = SGCMTimeMultiply(scale, obj.scale);
        }
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
- (CMTime)convertDuration:(CMTime)duration
{
    for (SGTimeLayout *obj in self->_timeLayouts) {
        duration = [obj convertDuration:duration];
    }
    return duration;
}

- (CMTime)convertTimeStamp:(CMTime)timeStamp
{
    for (SGTimeLayout *obj in self->_timeLayouts) {
        timeStamp = [obj convertTimeStamp:timeStamp];
    }
    return timeStamp;
}

- (void)fillToDescriptor:(SGCodecDescriptor *)descriptor
{
    descriptor->_track = self->_track;
    descriptor->_scale = self->_scale;
    descriptor->_metadata = self->_metadata;
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
