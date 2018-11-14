//
//  SGMutableAsset.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGMutableAsset.h"
#import "SGAsset+Internal.h"
#import "SGConcatDemuxer.h"

@interface SGMutableAsset ()

@property (nonatomic, strong) NSMutableArray <NSMutableArray <SGSegment *> *> * tracks;

@end

@implementation SGMutableAsset

- (id <SGDemuxable>)newDemuxable
{
    for (NSMutableArray <SGSegment *> * segments in self.tracks) {
        NSMutableArray * obj = [NSMutableArray array];
        for (SGSegment * segment in segments) {
            [obj addObject:[[SGConcatDemuxerUnit alloc] initWithSegment:[segment copy]]];
        }
        SGConcatDemuxer * demuxer = [[SGConcatDemuxer alloc] initWithUnits:obj];
        return demuxer;
    }
    return nil;
}

- (int64_t)addTrack
{
    if (!self.tracks) {
        self.tracks = [NSMutableArray array];
    }
    [self.tracks addObject:[NSMutableArray array]];
    return self.tracks.count - 1;
}

- (BOOL)insertSegment:(SGSegment *)segment trackID:(int64_t)trackID
{
    if (trackID < 0 || trackID >= self.tracks.count) {
        return NO;
    }
    [[self.tracks objectAtIndex:(NSUInteger)trackID] addObject:segment];
    return YES;
}

@end
