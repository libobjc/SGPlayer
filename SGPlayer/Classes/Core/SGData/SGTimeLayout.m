//
//  SGTimeLayout.m
//  SGPlayer
//
//  Created by Single on 2018/11/15.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGTimeLayout.h"

@implementation SGTimeLayout

- (id)copyWithZone:(NSZone *)zone
{
    SGTimeLayout *obj = [[SGTimeLayout alloc] init];
    obj->_scale = self->_scale;
    obj->_offset = self->_offset;
    return obj;
}

- (instancetype)initWithScale:(CMTime)scale
{
    if (self = [super init]) {
        self->_scale = SGCMTimeValidate(scale, CMTimeMake(1, 1), NO);
        self->_offset = kCMTimeInvalid;
    }
    return self;
}

- (instancetype)initWithOffset:(CMTime)offset
{
    if (self = [super init]) {
        self->_scale = kCMTimeInvalid;
        self->_offset = SGCMTimeValidate(offset, kCMTimeZero, NO);
    }
    return self;
}

- (CMTime)convertDuration:(CMTime)duration
{
    if (CMTIME_IS_NUMERIC(self->_scale)) {
        duration = SGCMTimeMultiply(duration, self->_scale);
    }
    return duration;
}

- (CMTime)convertTimeStamp:(CMTime)timeStamp
{
    if (CMTIME_IS_NUMERIC(self->_scale)) {
        timeStamp = SGCMTimeMultiply(timeStamp, self->_scale);
    }
    if (CMTIME_IS_NUMERIC(self->_offset)) {
        timeStamp = CMTimeAdd(timeStamp, self->_offset);
    }
    return timeStamp;
}

- (CMTime)reconvertTimeStamp:(CMTime)timeStamp
{
    if (CMTIME_IS_NUMERIC(self->_scale)) {
        timeStamp = SGCMTimeDivide(timeStamp, self->_scale);
    }
    if (CMTIME_IS_NUMERIC(self->_offset)) {
        timeStamp = CMTimeSubtract(timeStamp, self->_offset);
    }
    return timeStamp;
}

- (BOOL)isEqualToTimeLayout:(SGTimeLayout *)timeLayout
{
    if (!timeLayout) {
        return NO;
    }
    if (CMTimeCompare(timeLayout->_scale, self->_scale) != 0) {
        return NO;
    }
    if (CMTimeCompare(timeLayout->_offset, self->_offset) != 0) {
        return NO;
    }
    return YES;
}

@end
