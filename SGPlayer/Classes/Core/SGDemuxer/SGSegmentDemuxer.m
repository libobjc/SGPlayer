//
//  SGSegmentDemuxer.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGSegmentDemuxer.h"
#import "SGPacket+Internal.h"
#import "SGSegment+Internal.h"
#import "SGError.h"
#import "SGMacro.h"

@interface SGSegmentDemuxer ()

@property (nonatomic, strong, readonly) SGTimeLayout *timeLayout;
@property (nonatomic, strong, readonly) id<SGDemuxable> demuxable;

@end

@implementation SGSegmentDemuxer

@synthesize duration = _duration;

- (instancetype)initWithSegment:(SGSegment *)segment basetime:(CMTime)basetime
{
    if (self = [super init]) {
        self->_segment = segment;
        self->_basetime = basetime;
        self->_demuxable = [segment newDemuxable];
        self->_timeLayout = [[SGTimeLayout alloc] initWithStart:basetime scale:segment.scale];
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

#pragma mark - Control

- (NSError *)open
{
    if (!self->_demuxable) {
        CMTime duration = self->_segment.timeRange.duration;
        NSAssert(SGCMTimeIsValid(duration, NO), @"Invaild Duration.");
        self->_duration = SGCMTimeMultiply(duration, self->_segment.scale);
        return nil;
    }
    NSError *error = [self->_demuxable open];
    if (error) {
        return error;
    }
    CMTime duration = self->_demuxable.duration;
    NSAssert(SGCMTimeIsValid(duration, NO), @"Invaild Duration.");
    self->_duration = SGCMTimeMultiply(duration, self->_segment.scale);
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    if (!self->_demuxable) {
        return nil;
    }
    time = SGCMTimeDivide(time, self->_segment.scale);
    return [self->_demuxable seekToTime:time];
}

- (NSError *)nextPacket:(SGPacket **)packet
{
    if (!self->_demuxable) {
        return SGECreateError(SGErrorCodeDemuxerEndOfFile, SGOperationCodeSegmentDemuxerNext);
    }
    NSError *error = [self->_demuxable nextPacket:packet];
    if (error) {
        return error;
    }
    [(*packet).codecDescription appendTimeLayout:self->_timeLayout];
    [(*packet) fill];
    return nil;
}

@end
