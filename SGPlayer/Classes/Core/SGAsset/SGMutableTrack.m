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
    obj->_segments = [self->_segments copy];
    return obj;
}

- (instancetype)initWithType:(SGMediaType)type index:(int)index
{
    if (self = [super initWithType:type index:index]) {
        self->_segments = [NSMutableArray array];
    }
    return self;
}

- (BOOL)insertSegment:(SGSegment *)segment
{
    [self->_segments addObject:segment];
    return YES;
}

- (NSArray<SGSegment *> *)segments
{
    return [self->_segments copy];
}

@end
