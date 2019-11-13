//
//  SGTrack.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGTrack.h"
#import "SGTrack+Internal.h"

SGTrack *SGTrackWithIndex(NSArray<SGTrack *> *tracks, NSInteger index)
{
    for (SGTrack *obj in tracks) {
        if (obj.index == index) {
            return obj;
        }
    }
    return nil;
}

SGTrack *SGTrackWithType(NSArray<SGTrack *> *tracks, SGMediaType type)
{
    for (SGTrack *obj in tracks) {
        if (obj.type == type) {
            return obj;
        }
    }
    return nil;
}

NSArray<SGTrack *> *SGTracksWithType(NSArray<SGTrack *> *tracks, SGMediaType type)
{
    NSMutableArray *array = [NSMutableArray array];
    for (SGTrack *obj in tracks) {
        if (obj.type == type) {
            [array addObject:obj];
        }
    }
    return array.count ? [array copy] : nil;
}

@implementation SGTrack

- (id)copyWithZone:(NSZone *)zone
{
    SGTrack *obj = [[self.class alloc] init];
    obj->_type = self->_type;
    obj->_index = self->_index;
    obj->_core = self->_core;
    return obj;
}

- (instancetype)initWithType:(SGMediaType)type index:(NSInteger)index
{
    if (self = [super init]) {
        self->_type = type;
        self->_index = index;
    }
    return self;
}

- (void *)coreptr
{
    return self->_core;
}

@end
