//
//  SGCodecDescription.m
//  SGPlayer
//
//  Created by Single on 2018/11/15.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGCodecDescription.h"

@interface SGCodecDescription ()

{
    __strong NSMutableArray <SGTimeLayout *> * _timeLayouts;
}

@end

@implementation SGCodecDescription

- (id)copyWithZone:(NSZone *)zone
{
    SGCodecDescription * obj = [[SGCodecDescription alloc] init];
    obj->_timeLayouts = [self->_timeLayouts mutableCopy];
    obj->_timebase = self->_timebase;
    obj->_codecpar = self->_codecpar;
    return obj;
}

- (NSArray <SGTimeLayout *> *)timeLayouts
{
    return [_timeLayouts copy];
}

- (BOOL)isEqualToDescription:(SGCodecDescription *)codecpar
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
    if (![codecpar.decodeableClass isEqual:self.decodeableClass]) {
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

- (void)setDecodeableClass:(Class)decodeableClass
{
    _decodeableClass = decodeableClass;
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
    _decodeableClass = nil;
    _codecpar = nil;
    _timebase = av_make_q(0, 1);
    [_timeLayouts removeAllObjects];
}

@end
