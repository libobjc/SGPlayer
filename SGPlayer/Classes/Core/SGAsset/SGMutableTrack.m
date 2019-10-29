//
//  SGMutableTrack.m
//  SGPlayer
//
//  Created by Single on 2018/11/29.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGMutableTrack.h"
#import "SGTrack+Internal.h"

@interface SGMutableTrack ()

{
    NSMutableArray<SGSegment *> *_segments;
}

@end

@implementation SGMutableTrack

- (id)copyWithZone:(NSZone *)zone
{
    SGMutableTrack *obj = [super copyWithZone:zone];
    obj->_segments = [self->_segments mutableCopy];
    obj->_subTracks = [self->_subTracks copy];
    return obj;
}

- (instancetype)initWithType:(SGMediaType)type index:(NSInteger)index
{
    if (self = [super initWithType:type index:index]) {
        self->_segments = [NSMutableArray array];
    }
    return self;
}

- (void *)coreptr
{
    void *ret = [super coreptr];
    if (ret) {
        return ret;
    }
    for (SGTrack *obj in self->_subTracks) {
        if (obj.coreptr) {
            ret = obj.coreptr;
            break;
        }
    }
    return ret;
}

- (BOOL)appendSegment:(SGSegment *)segment
{
    [self->_segments addObject:segment];
    return YES;
}

@end
