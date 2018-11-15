//
//  SGCodecpar.m
//  SGPlayer
//
//  Created by Single on 2018/11/15.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGCodecpar.h"

@interface SGCodecpar ()

{
    __strong NSMutableArray <SGTimeLayout *> * _timeLayouts;
}

@end

@implementation SGCodecpar

- (id)copyWithZone:(NSZone *)zone
{
    SGCodecpar * obj = [[SGCodecpar alloc] init];
    obj->_timeLayouts = [self->_timeLayouts mutableCopy];
    obj->_timebase = self->_timebase;
    obj->_codecpar = self->_codecpar;
    return obj;
}

- (NSArray <SGTimeLayout *> *)timeLayouts
{
    return [_timeLayouts copy];
}

- (BOOL)isEqualToCodecpar:(SGCodecpar *)codecpar
{
    if (!codecpar) {
        return NO;
    }
    if (codecpar->_codecpar != _codecpar) {
        return NO;
    }
    if (av_cmp_q(codecpar->_timebase, _timebase) != 0) {
        return NO;
    }
    if (codecpar->_timeLayouts.count != self->_timeLayouts.count) {
        return NO;
    }
    for (int i = 0; i < codecpar->_timeLayouts.count; i++) {
        SGTimeLayout * t1 = [codecpar->_timeLayouts objectAtIndex:i];
        SGTimeLayout * t2 = [self->_timeLayouts objectAtIndex:i];
        if (![t1 isEqualToTimeLayout:t2]) {
            return NO;
        }
    }
    return YES;
}

- (void)setTimebase:(AVRational)timebase codecpar:(AVCodecParameters *)codecpar
{
    _codecpar = codecpar;
    _timebase = timebase;
}

- (void)setTimeLayout:(SGTimeLayout *)timeLayout
{
    if (!_timeLayouts) {
        _timeLayouts = [NSMutableArray array];
    }
    [_timeLayouts addObject:timeLayout];
}

- (void)clear
{
    _codecpar = nil;
    _timebase = av_make_q(0, 1);
    [_timeLayouts removeAllObjects];
}

@end
