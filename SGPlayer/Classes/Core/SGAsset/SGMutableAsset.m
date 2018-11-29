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

{
    NSMutableArray<SGMutableTrack *> *_tracks;
}

@end

@implementation SGMutableAsset

- (instancetype)init
{
    if (self = [super init]) {
        _tracks = [NSMutableArray array];
    }
    return self;
}

- (SGMutableTrack *)addTrack:(SGMediaType)type
{
    SGMutableTrack *obj = [[SGMutableTrack alloc] initWithType:type index:(int)self->_tracks.count];
    [self->_tracks addObject:obj];
    return obj;
}

- (id<SGDemuxable>)newDemuxable
{
    NSMutableArray *demuxables = [NSMutableArray array];
    for (SGMutableTrack *obj in self->_tracks) {
        SGConcatDemuxer *demuxer = [[SGConcatDemuxer alloc] initWithTrack:obj];
        [demuxables addObject:demuxer];
    }
    return [[SGMutilDemuxer alloc] initWithDemuxables:demuxables];
}

@end
