//
//  SGTrack.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGTrack.h"
#import "SGTrack+Internal.h"

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
