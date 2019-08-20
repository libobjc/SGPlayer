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
#import "SGTrackDemuxer.h"
#import "SGMutilDemuxer.h"

@interface SGMutableAsset ()

{
    NSMutableArray<SGMutableTrack *> *_tracks;
}

@end

@implementation SGMutableAsset

- (id)copyWithZone:(NSZone *)zone
{
    SGMutableAsset *obj = [super copyWithZone:zone];
    obj->_tracks = [self->_tracks mutableCopy];
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_tracks = [NSMutableArray array];
    }
    return self;
}

- (NSArray<SGMutableTrack *> *)tracks
{
    return [self->_tracks copy];
}

- (SGMutableTrack *)addTrack:(SGMediaType)type
{
    NSInteger index = self->_tracks.count;
    SGMutableTrack *obj = [[SGMutableTrack alloc] initWithType:type index:index];
    [self->_tracks addObject:obj];
    return obj;
}

- (id<SGDemuxable>)newDemuxable
{
    NSMutableArray *demuxables = [NSMutableArray array];
    for (SGMutableTrack *obj in self->_tracks) {
        SGTrackDemuxer *demuxer = [[SGTrackDemuxer alloc] initWithTrack:obj];
        [demuxables addObject:demuxer];
    }
    return [[SGMutilDemuxer alloc] initWithDemuxables:demuxables];
}

@end
