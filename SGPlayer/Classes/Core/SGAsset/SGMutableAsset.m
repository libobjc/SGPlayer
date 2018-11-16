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

@property (nonatomic, strong) NSMutableArray <NSNumber *> * types;
@property (nonatomic, strong) NSMutableArray <NSMutableArray <SGSegment *> *> * tracks;

@end

@implementation SGMutableAsset

- (id <SGDemuxable>)newDemuxable
{
    NSMutableArray * demuxables = [NSMutableArray array];
    for (int i = 0; i < self.tracks.count; i++) {
        SGMediaType type = (uint32_t)[self.types objectAtIndex:i].unsignedIntValue;
        NSMutableArray <SGSegment *> * segments = [self.tracks objectAtIndex:i];
        NSMutableArray * obj = [NSMutableArray array];
        for (SGSegment * segment in segments) {
            [obj addObject:[segment copy]];
        }
        SGTrack * track = [[SGTrack alloc] initWithType:type index:i];
        SGConcatDemuxer * demuxer = [[SGConcatDemuxer alloc] initWithTrack:track segments:segments];
        [demuxables addObject:demuxer];
    }
    return [[SGMutilDemuxer alloc] initWithDemuxables:demuxables];
}

- (int32_t)addTrack:(SGMediaType)type
{
    if (!self.types) {
        self.types = [NSMutableArray array];
    }
    if (!self.tracks) {
        self.tracks = [NSMutableArray array];
    }
    [self.types addObject:@(type)];
    [self.tracks addObject:[NSMutableArray array]];
    return (int32_t)self.tracks.count - 1;
}

- (BOOL)insertSegment:(SGSegment *)segment trackID:(int32_t)trackID
{
    if (trackID < 0 || trackID >= self.tracks.count) {
        return NO;
    }
    [[self.tracks objectAtIndex:(NSUInteger)trackID] addObject:segment];
    return YES;
}

@end
