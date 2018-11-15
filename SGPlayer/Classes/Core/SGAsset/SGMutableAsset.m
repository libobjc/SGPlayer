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

@property (nonatomic, strong) NSMutableArray <NSNumber *> * types;
@property (nonatomic, strong) NSMutableArray <NSMutableArray <SGSegment *> *> * tracks;

@end

@implementation SGMutableAsset

- (id <SGDemuxable>)newDemuxable
{
    for (int i = 0; i < self.tracks.count; i++) {
        SGMediaType type = (uint32_t)[self.types objectAtIndex:i].unsignedIntValue;
        NSMutableArray <SGSegment *> * segments = [self.tracks objectAtIndex:i];
        NSMutableArray * obj = [NSMutableArray array];
        for (SGSegment * segment in segments) {
            [obj addObject:[segment copy]];
        }
        SGConcatDemuxer * demuxer = [[SGConcatDemuxer alloc] initWithType:type segments:obj];
        return demuxer;
    }
    return nil;
}

- (int64_t)addTrack:(SGMediaType)type
{
    if (!self.types) {
        self.types = [NSMutableArray array];
    }
    if (!self.tracks) {
        self.tracks = [NSMutableArray array];
    }
    [self.types addObject:@(type)];
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
