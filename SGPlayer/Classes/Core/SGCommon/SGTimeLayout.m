//
//  SGTimeLayout.m
//  SGPlayer
//
//  Created by Single on 2018/11/15.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGTimeLayout.h"

@interface SGTimeLayout ()

{
    CMTime _start;
    CMTime _scale;
}

@end

@implementation SGTimeLayout

- (id)copyWithZone:(NSZone *)zone
{
    SGTimeLayout *obj = [[SGTimeLayout alloc] initWithStart:self->_start scale:self->_scale];
    return obj;
}

- (instancetype)init
{
    return [self initWithStart:kCMTimeInvalid scale:kCMTimeInvalid];
}

- (instancetype)initWithStart:(CMTime)start scale:(CMTime)scale
{
    if (self = [super init]) {
        self->_start = start;
        self->_scale = scale;
    }
    return self;
}

- (CMTime)start
{
    return self->_start;
}

- (CMTime)scale
{
    return self->_scale;
}

- (BOOL)isEqualToTimeLayout:(SGTimeLayout *)timeLayout
{
    if (!timeLayout) {
        return NO;
    }
    if (CMTimeCompare(timeLayout->_start, self->_start) != 0) {
        return NO;
    }
    if (CMTimeCompare(timeLayout->_scale, self->_scale) != 0) {
        return NO;
    }
    return YES;
}

- (CMTime)convertTimeStamp:(CMTime)timeStamp
{
    if (CMTIME_IS_VALID(_start)) {
        return CMTimeAdd(timeStamp, self->_start);
    }
    return timeStamp;
}

- (CMTime)convertDuration:(CMTime)duration
{
    return duration;
}

@end
