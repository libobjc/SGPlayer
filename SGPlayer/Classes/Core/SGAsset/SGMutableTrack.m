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

@property (nonatomic, strong, readonly) NSMutableArray<SGSegment *> *mutableSegments;

@end

@implementation SGMutableTrack

- (id)copyWithZone:(NSZone *)zone
{
    SGMutableTrack *obj = [super copyWithZone:zone];
    obj->_mutableSegments = [self->_mutableSegments mutableCopy];
    return obj;
}

- (instancetype)initWithType:(SGMediaType)type index:(NSInteger)index
{
    if (self = [super initWithType:type index:index]) {
        self->_mutableSegments = [NSMutableArray array];
    }
    return self;
}

- (NSArray<SGSegment *> *)segments
{
    return [self->_mutableSegments copy];
}

- (BOOL)appendSegment:(SGSegment *)segment
{
    [self->_mutableSegments addObject:segment];
    return YES;
}

@end
