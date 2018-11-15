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
    SGTimeLayout * obj = [[SGTimeLayout alloc] init];
    obj->_start = self->_start;
    obj->_scale = self->_scale;
    return obj;
}

- (instancetype)init
{
    return [self initWithStart:kCMTimeInvalid scale:kCMTimeInvalid];
}

- (instancetype)initWithStart:(CMTime)start scale:(CMTime)scale
{
    if (self = [super init]) {
        _start = start;
        _scale = scale;
    }
    return self;
}

- (BOOL)isEqualToTimeLayout:(SGTimeLayout *)timeLayout
{
    if (!timeLayout) {
        return NO;
    }
    if (CMTimeCompare(timeLayout->_start, _start) != 0) {
        return NO;
    }
    if (CMTimeCompare(timeLayout->_scale, _scale) != 0) {
        return NO;
    }
    return YES;
}

- (CMTime)applyToTimeStamp:(CMTime)timeStamp
{
    if (CMTIME_IS_VALID(_start)) {
        return CMTimeAdd(timeStamp, _start);
    }
    return timeStamp;
}

- (CMTime)applyToDuration:(CMTime)duration
{
    return duration;
}

@end
