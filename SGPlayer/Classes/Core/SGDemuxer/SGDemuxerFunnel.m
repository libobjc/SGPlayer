//
//  SGDemuxerFunnel.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDemuxerFunnel.h"
#import "SGPacket+Internal.h"
#import "SGObjectQueue.h"
#import "SGError.h"
#import "SGMacro.h"

@interface SGDemuxerFunnel ()

{
    SGTrack *_track;
    SGTimeLayout *_layout;
    SGObjectQueue *_queue;
    id<SGDemuxable> _demuxable;
    
    BOOL _outputValid;
    BOOL _outputStarted;
    BOOL _outputFinished;
}

@end

@implementation SGDemuxerFunnel

- (instancetype)initWithDemuxable:(id<SGDemuxable>)demuxable
{
    if (self = [super init]) {
        self->_demuxable = demuxable;
        self->_queue = [[SGObjectQueue alloc] init];
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
    return self->_timeRange.duration;
}

- (NSArray<SGTrack *> *)tracks
{
    if (!self->_track) {
        return nil;
    }
    return @[self->_track];
}

#pragma mark - Control

- (NSError *)open
{
    NSError *ret = [self->_demuxable open];
    if (ret) {
        return ret;
    }
    for (SGTrack *obj in self->_demuxable.tracks) {
        if (self->_index == obj.index) {
            self->_track = obj;
            break;
        }
    }
    CMTimeRange preferredTimeRange = self->_timeRange;
    CMTime start = CMTIME_IS_VALID(preferredTimeRange.start) ? preferredTimeRange.start : kCMTimeNegativeInfinity;
    CMTime duration = CMTIME_IS_VALID(preferredTimeRange.duration) ? preferredTimeRange.duration : kCMTimePositiveInfinity;
    self->_timeRange = CMTimeRangeGetIntersection(CMTimeRangeMake(start, duration),
                                                  CMTimeRangeMake(kCMTimeZero, self->_demuxable.duration));
    self->_layout = [[SGTimeLayout alloc] initWithStart:CMTimeMultiply(self->_timeRange.start, -1)
                                                  scale:kCMTimeInvalid];
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    NSError *ret = [self->_demuxable seekToTime:CMTimeAdd(time, self->_timeRange.start)];
    if (ret) {
        return ret;
    }
    [self->_queue flush];
    self->_outputValid = NO;
    self->_outputStarted = NO;
    self->_outputFinished = NO;
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
        if (self->_index != pkt.track.index) {
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, self->_timeRange.start) < 0) {
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, CMTimeRangeGetEnd(self->_timeRange)) >= 0) {
            [pkt unlock];
            ret = SGECreateError(SGErrorCodeURLDemuxerFunnelFinished,
                                 SGOperationCodeURLDemuxerFunnelNext);
            break;
        }
        [pkt.codecDescription appendTimeLayout:self->_layout];
        [pkt.codecDescription appendTimeRange:self->_timeRange];
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
        if (self->_outputStarted) {
            [self->_queue getObjectAsync:&pkt];
            if (pkt) {
                [pkt.codecDescription appendTimeLayout:self->_layout];
                [pkt.codecDescription appendTimeRange:self->_timeRange];
                [pkt fill];
                *packet = pkt;
                break;
            }
        }
        if (self->_outputFinished) {
            ret = SGECreateError(SGErrorCodeURLDemuxerFunnelFinished,
                                 SGOperationCodeURLDemuxerFunnelNext);
            break;
        }
        ret = [self->_demuxable nextPacket:&pkt];
        if (ret) {
            if (ret.code == SGErrorImmediateExitRequested) {
                break;
            }
            self->_outputFinished = YES;
            continue;
        }
        if (self->_index != pkt.track.index) {
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, self->_timeRange.start) < 0) {
            if (pkt.core->flags & AV_PKT_FLAG_KEY) {
                [self->_queue flush];
                self->_outputValid = YES;
            }
            if (self->_outputValid) {
                [self->_queue putObjectSync:pkt];
            }
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, CMTimeRangeGetEnd(self->_timeRange)) >= 0) {
            if (pkt.core->flags & AV_PKT_FLAG_KEY) {
                self->_outputFinished = YES;
            } else {
                [self->_queue putObjectSync:pkt];
            }
            [pkt unlock];
            continue;
        }
        if (!self->_outputStarted && pkt.core->flags & AV_PKT_FLAG_KEY) {
            [self->_queue flush];
        }
        self->_outputStarted = YES;
        [self->_queue putObjectSync:pkt];
        [pkt unlock];
        continue;
    }
    return ret;
}

@end
