//
//  SGMutableAsset.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGMutableAsset.h"
#import "SGAsset+Internal.h"
#import "SGTrack+Internal.h"
#import "SGConcatDemuxer.h"
#import "SGMutilDemuxer.h"

@interface SGMutableAsset ()

@property (nonatomic, strong, readonly) NSMutableArray<SGMutableTrack *> *mutableTracks;

@end

@implementation SGMutableAsset

- (id)copyWithZone:(NSZone *)zone
{
    SGMutableAsset *obj = [super copyWithZone:zone];
    obj->_mutableTracks = [self->_mutableTracks mutableCopy];
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_mutableTracks = [NSMutableArray array];
    }
    return self;
}

- (NSArray<SGMutableTrack *> *)tracks
{
    return [self->_mutableTracks copy];
}

- (SGMutableTrack *)addTrack:(SGMediaType)type
{
    NSInteger index = self->_mutableTracks.count;
    SGMutableTrack *obj = [[SGMutableTrack alloc] initWithType:type index:index];
    [self->_mutableTracks addObject:obj];
    return obj;
}

- (id<SGDemuxable>)newDemuxable
{
    NSMutableArray *demuxables = [NSMutableArray array];
    for (SGMutableTrack *obj in self->_mutableTracks) {
        SGConcatDemuxer *demuxer = [[SGConcatDemuxer alloc] initWithTrack:obj];
        [demuxables addObject:demuxer];
    }
    return [[SGMutilDemuxer alloc] initWithDemuxables:demuxables];
}

@end
