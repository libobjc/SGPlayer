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
#import "SGMacro.h"

@interface SGConcatDemuxerUnit ()

{
    CMTime _duration;
    SGSegment *_segment;
    id<SGDemuxable> _demuxable;
}

@end

@implementation SGConcatDemuxerUnit

- (instancetype)initWithSegment:(SGSegment *)segment
{
    if (self = [super init]) {
        self->_segment = segment;
        self->_demuxable = [segment newDemuxable];
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

#pragma mark - Mapping

SGGet0Map(id<SGDemuxableDelegate>, delegate, self->_demuxable)
SGSet1Map(void, setDelegate, id<SGDemuxableDelegate>, self->_demuxable)
SGGet0Map(NSDictionary *, options, self->_demuxable)
SGSet1Map(void, setOptions, NSDictionary *, self->_demuxable)
SGGet0Map(NSDictionary *, metadata, self->_demuxable)
SGGet0Map(NSArray<SGTrack *> *, tracks, self->_demuxable)
SGGet0Map(NSError *, close, self->_demuxable)
SGGet0Map(NSError *, seekable, self->_demuxable)

#pragma mark - Setter & Getter

- (CMTime)duration
{
    return self->_duration;
}

#pragma mark - Control

- (NSError *)open
{
    if (!self->_demuxable) {
        self->_duration = self->_segment.timeRange.duration;
        NSAssert(CMTIME_IS_VALID(self->_duration), @"Invaild timeRange.");
        return nil;
    }
    if (!self->_demuxable) {
        return nil;
    }
    NSError *ret = [self->_demuxable open];
    if (ret) {
        return ret;
    }
    self->_duration = self->_demuxable.duration;
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    return [self->_demuxable seekToTime:time];
}

- (NSError *)nextPacket:(SGPacket **)packet
{
    NSError *ret = [self->_demuxable nextPacket:packet];
    if (ret) {
        return ret;
    }
    SGTimeLayout *layout = [[SGTimeLayout alloc] initWithStart:self->_timeRange.start scale:kCMTimeInvalid];
    [(*packet).codecDescription appendTimeLayout:layout];
    [(*packet) fill];
    return nil;
}

@end
