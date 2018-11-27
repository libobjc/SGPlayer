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
    NSMutableArray<NSNumber *> *_types;
    NSMutableArray<NSMutableArray<SGSegment *> *> *_tracks;
}

@end

@implementation SGMutableAsset

- (instancetype)init
{
    if (self = [super init]) {
        _types = [NSMutableArray array];
        _tracks = [NSMutableArray array];
    }
    return self;
}

- (int)addTrack:(SGMediaType)type
{
    [self->_types addObject:@(type)];
    [self->_tracks addObject:[NSMutableArray array]];
    return (int32_t)self->_tracks.count - 1;
}

- (BOOL)insertSegment:(SGSegment *)segment trackID:(int)trackID
{
    if (trackID < 0 || trackID >= self->_tracks.count) {
        return NO;
    }
    [[self->_tracks objectAtIndex:trackID] addObject:segment];
    return YES;
}

- (id<SGDemuxable>)newDemuxable
{
    NSMutableArray *demuxables = [NSMutableArray array];
    for (int i = 0; i < self->_tracks.count; i++) {
        SGMediaType type = [self->_types objectAtIndex:i].intValue;
        NSMutableArray<SGSegment *> *segments = [self->_tracks objectAtIndex:i];
        NSMutableArray *obj = [NSMutableArray array];
        for (SGSegment *segment in segments) {
            [obj addObject:[segment copy]];
        }
        SGTrack *track = [[SGTrack alloc] initWithType:type index:i];
        SGConcatDemuxer *demuxer = [[SGConcatDemuxer alloc] initWithTrack:track segments:segments];
        [demuxables addObject:demuxer];
    }
    return [[SGMutilDemuxer alloc] initWithDemuxables:demuxables];
}

@end
