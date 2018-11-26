//
//  SGDemuxerFunnel.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDemuxerFunnel.h"
#import "SGPacket+Internal.h"
#import "SGError.h"
#import "SGMacro.h"

@interface SGDemuxerFunnel ()

{
    BOOL _isGOPValid;
    BOOL _isGOPEndOutput;
    BOOL _isGOPStartOutput;
    SGTimeLayout *_timeLayout;
    id<SGDemuxable> _demuxable;
    CMTimeRange _finalTimeRange;
    SGObjectQueue *_objectQueue;
    NSArray<SGTrack *> *_tracks;
}

@end

@implementation SGDemuxerFunnel

- (instancetype)initWithDemuxable:(id<SGDemuxable>)demuxable
{
    if (self = [super init]) {
        self->_demuxable = demuxable;
        self->_objectQueue = [[SGObjectQueue alloc] init];
        self->_overgop = YES;
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
SGGet0Map(NSError *, close, self->_demuxable)
SGGet0Map(NSError *, seekable, self->_demuxable)

#pragma mark - Setter & Getter

- (CMTime)duration
{
    return self->_finalTimeRange.duration;
}

- (NSArray<SGTrack *> *)tracks
{
    return [self->_tracks copy];
}

#pragma mark - Control

- (NSError *)open
{
    NSError *ret = [self->_demuxable open];
    if (ret) {
        return ret;
    }
    CMTime start = CMTIME_IS_VALID(self->_timeRange.start) ? self->_timeRange.start : kCMTimeNegativeInfinity;
    CMTime duration = CMTIME_IS_VALID(self->_timeRange.duration) ? self->_timeRange.duration : kCMTimePositiveInfinity;
    self->_finalTimeRange = CMTimeRangeGetIntersection(CMTimeRangeMake(start, duration),
                                                        CMTimeRangeMake(kCMTimeZero, self->_demuxable.duration));
    NSMutableArray<SGTrack *> *tracks = [NSMutableArray array];
    for (SGTrack *obj in self->_demuxable.tracks) {
        if ([self->_indexes containsObject:@(obj.index)]) {
            [tracks addObject:obj];
        }
    }
    self->_tracks = [tracks copy];
    self->_timeLayout = [[SGTimeLayout alloc] initWithStart:CMTimeMultiply(self->_finalTimeRange.start, -1)
                                                      scale:kCMTimeInvalid];
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    NSError *ret = [self->_demuxable seekToTime:CMTimeAdd(time, self->_finalTimeRange.start)];
    if (ret) {
        return ret;
    }
    [self->_objectQueue flush];
    self->_isGOPValid = NO;
    self->_isGOPStartOutput = NO;
    self->_isGOPEndOutput = NO;
    return nil;
}

- (NSError *)nextPacket:(SGPacket **)packet
{
    if (!self->_overgop) {
        return [self nextPacketInternal:packet];
    }
    return [self nextPacketInternalOvergop:packet];
}

- (NSError *)nextPacketInternal:(SGPacket **)packet
{
    NSError *ret = nil;
    while (YES) {
        SGPacket *pkt = nil;
        ret = [self->_demuxable nextPacket:&pkt];
        if (ret) {
            break;
        }
        if (![self->_indexes containsObject:@(pkt.track.index)]) {
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, self->_finalTimeRange.start) < 0) {
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, CMTimeRangeGetEnd(self->_finalTimeRange)) >= 0) {
            [pkt unlock];
            ret = SGECreateError(SGErrorCodeURLDemuxerFunnelFinished,
                                 SGOperationCodeURLDemuxerFunnelNext);
            break;
        }
        [pkt.codecDescription appendTimeLayout:self->_timeLayout];
        [pkt.codecDescription appendTimeRange:self->_finalTimeRange];
        [pkt fill];
        *packet = pkt;
        break;
    }
    return ret;
}

- (NSError *)nextPacketInternalOvergop:(SGPacket **)packet
{
    NSError *ret = nil;
    while (YES) {
        SGPacket *pkt = nil;
        if (self->_isGOPStartOutput) {
            [self->_objectQueue getObjectAsync:&pkt];
            if (pkt) {
                [pkt.codecDescription appendTimeLayout:self->_timeLayout];
                [pkt.codecDescription appendTimeRange:self->_finalTimeRange];
                [pkt fill];
                *packet = pkt;
                break;
            }
        }
        if (self->_isGOPEndOutput) {
            ret = SGECreateError(SGErrorCodeURLDemuxerFunnelFinished,
                                 SGOperationCodeURLDemuxerFunnelNext);
            break;
        }
        ret = [self->_demuxable nextPacket:&pkt];
        if (ret) {
            self->_isGOPEndOutput = YES;
            continue;
        }
        if (![self->_indexes containsObject:@(pkt.track.index)]) {
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, self->_finalTimeRange.start) < 0) {
            if (pkt.core->flags & AV_PKT_FLAG_KEY) {
                [self->_objectQueue flush];
                self->_isGOPValid = YES;
            }
            if (self->_isGOPValid) {
                [self->_objectQueue putObjectSync:pkt];
            }
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, CMTimeRangeGetEnd(self->_finalTimeRange)) >= 0) {
            if (pkt.core->flags & AV_PKT_FLAG_KEY) {
                self->_isGOPEndOutput = YES;
            } else {
                [self->_objectQueue putObjectSync:pkt];
            }
            [pkt unlock];
            continue;
        }
        if (!self->_isGOPStartOutput && pkt.core->flags & AV_PKT_FLAG_KEY) {
            [self->_objectQueue flush];
        }
        self->_isGOPStartOutput = YES;
        [self->_objectQueue putObjectSync:pkt];
        [pkt unlock];
        continue;
    }
    return ret;
}

@end
