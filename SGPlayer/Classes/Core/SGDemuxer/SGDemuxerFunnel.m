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
    struct {
        BOOL putting;
        BOOL finished;
        BOOL outputting;
    } _flags;
}

@property (nonatomic, strong, readonly) SGTrack *track;
@property (nonatomic, strong, readonly) SGTimeLayout *timeLayout;
@property (nonatomic, strong, readonly) id<SGDemuxable> demuxable;
@property (nonatomic, strong, readonly) SGObjectQueue *packetQueue;

@end

@implementation SGDemuxerFunnel

@synthesize tracks = _tracks;
@synthesize duration = _duration;

- (instancetype)initWithDemuxable:(id<SGDemuxable>)demuxable index:(NSInteger)index timeRange:(CMTimeRange)timeRange
{
    if (self = [super init]) {
        self->_demuxable = demuxable;
        self->_index = index;
        self->_timeRange = SGCMTimeRangeFit(timeRange);
        self->_timeLayout = [[SGTimeLayout alloc] initWithStart:CMTimeMultiply(SGCMTimeValidate(timeRange.start, kCMTimeZero, NO), -1) scale:kCMTimeInvalid];
        self->_overgop = YES;
        self->_packetQueue = [[SGObjectQueue alloc] init];
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
            self->_tracks = @[obj];
            break;
        }
    }
    if (SGCMTimeIsValid(self->_timeRange.duration, NO)) {
        self->_duration = self->_timeRange.duration;
    } else {
        self->_duration = self->_demuxable.duration;
    }
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    NSError *ret = [self->_demuxable seekToTime:CMTimeAdd(time, CMTimeMultiply(self->_timeLayout.start, -1))];
    if (ret) {
        return ret;
    }
    [self->_packetQueue flush];
    self->_flags.putting = NO;
    self->_flags.finished = NO;
    self->_flags.outputting = NO;
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
        [pkt.codecDescription appendTimeLayout:self->_timeLayout];
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
        if (self->_flags.outputting) {
            [self->_packetQueue getObjectAsync:&pkt];
            if (pkt) {
                [pkt.codecDescription appendTimeLayout:self->_timeLayout];
                [pkt.codecDescription appendTimeRange:self->_timeRange];
                [pkt fill];
                *packet = pkt;
                break;
            }
        }
        if (self->_flags.finished) {
            ret = SGECreateError(SGErrorCodeURLDemuxerFunnelFinished,
                                 SGOperationCodeURLDemuxerFunnelNext);
            break;
        }
        ret = [self->_demuxable nextPacket:&pkt];
        if (ret) {
            if (ret.code == SGErrorImmediateExitRequested) {
                break;
            }
            self->_flags.finished = YES;
            continue;
        }
        if (self->_index != pkt.track.index) {
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, self->_timeRange.start) < 0) {
            if (pkt.core->flags & AV_PKT_FLAG_KEY) {
                [self->_packetQueue flush];
                self->_flags.putting = YES;
            }
            if (self->_flags.putting) {
                [self->_packetQueue putObjectSync:pkt];
            }
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, CMTimeRangeGetEnd(self->_timeRange)) >= 0) {
            if (pkt.core->flags & AV_PKT_FLAG_KEY) {
                self->_flags.finished = YES;
            } else {
                [self->_packetQueue putObjectSync:pkt];
            }
            [pkt unlock];
            continue;
        }
        if (!self->_flags.outputting && pkt.core->flags & AV_PKT_FLAG_KEY) {
            [self->_packetQueue flush];
        }
        self->_flags.outputting = YES;
        [self->_packetQueue putObjectSync:pkt];
        [pkt unlock];
        continue;
    }
    return ret;
}

@end
