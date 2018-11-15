//
//  SGConcatDemuxerUnit.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGConcatDemuxerUnit.h"
#import "SGSegment+Internal.h"
#import "SGPacket+Internal.h"
#import "SGError.h"
#import "SGMacro.h"

@interface SGConcatDemuxerUnit ()

@property (nonatomic, strong) id <SGDemuxable> demuxable;
@property (nonatomic) CMTime duration;

@end

@implementation SGConcatDemuxerUnit

- (instancetype)initWithSegment:(SGSegment *)segment
{
    if (self = [super init]) {
        _scale = segment.scale;
        self.demuxable = [segment newDemuxable];
        if (!self.demuxable) {
            CMTime duration = segment.timeRange.duration;
            NSAssert(CMTIME_IS_VALID(duration), @"Invaild timeRange.");
            self.duration = duration;
        }
    }
    return self;
}

SGGet0Map(id <SGDemuxableDelegate>, delegate, self.demuxable)
SGSet1Map(void, setDelegate, id <SGDemuxableDelegate>, self.demuxable)
SGGet0Map(NSDictionary *, options, self.demuxable)
SGSet1Map(void, setOptions, NSDictionary *, self.demuxable)
SGGet0Map(NSError *, seekable, self.demuxable)
SGGet0Map(NSDictionary *, metadata, self.demuxable)
SGGet0Map(NSArray <SGTrack *> *, tracks, self.demuxable)
SGGet0Map(NSArray <SGTrack *> *, audioTracks, self.demuxable)
SGGet0Map(NSArray <SGTrack *> *, videoTracks, self.demuxable)
SGGet0Map(NSArray <SGTrack *> *, otherTracks, self.demuxable)

- (NSError *)open
{
    if (!self.demuxable) {
        return nil;
    }
    NSError * ret = [self.demuxable open];
    if (ret) {
        return ret;
    }
    self.duration = self.demuxable.duration;
    return nil;
}

- (NSError *)close
{
    return [self.demuxable close];
}

- (NSError *)seekToTime:(CMTime)time
{
    return [self.demuxable seekToTime:time];
}

- (NSError *)nextPacket:(SGPacket *)packet
{
    NSError * ret = [self.demuxable nextPacket:packet];
    if (ret) {
        return ret;
    }
    SGTimeLayout * layout = [[SGTimeLayout alloc] initWithStart:self.timeRange.start scale:kCMTimeInvalid];
    [packet setTimeLayout:layout];
    return nil;
}

@end
