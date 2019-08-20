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
        self->_start = SGCMTimeValidate(start, kCMTimeZero, NO);
        self->_scale = SGCMTimeValidate(scale, CMTimeMake(1, 1), NO);
    }
    return self;
}

- (CMTime)convertTimeStamp:(CMTime)timeStamp
{
    return CMTimeAdd(SGCMTimeMultiply(timeStamp, self->_scale), self->_start);
}

- (CMTime)convertDuration:(CMTime)duration
{
    return SGCMTimeMultiply(duration, self->_scale);
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

@end
