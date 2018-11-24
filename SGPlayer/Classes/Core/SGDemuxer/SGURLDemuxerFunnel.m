//
//  SGURLDemuxerFunnel.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGURLDemuxerFunnel.h"
#import "SGPacket+Internal.h"
#import "SGURLDemuxer.h"
#import "SGError.h"
#import "SGMacro.h"

@interface SGURLDemuxerFunnel ()

{
    int32_t _is_valid;
    int32_t _is_end_output;
    int32_t _is_start_output;
    
    SGURLDemuxer *_demuxer;
    SGTimeLayout *_time_layout;
    NSArray<SGTrack *> *_tracks;
    SGObjectQueue *_object_queue;
    CMTimeRange _actual_time_range;
}

@end

@implementation SGURLDemuxerFunnel

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        self->_demuxer = [[SGURLDemuxer alloc] initWithURL:URL];
        self->_object_queue = [[SGObjectQueue alloc] init];
        self->_overgop = YES;
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

#pragma mark - Mapping

SGGet0Map(id<SGDemuxableDelegate>, delegate, self->_demuxer)
SGSet1Map(void, setDelegate, id<SGDemuxableDelegate>, self->_demuxer)
SGGet0Map(NSDictionary *, options, self->_demuxer)
SGSet1Map(void, setOptions, NSDictionary *, self->_demuxer)
SGGet0Map(NSDictionary *, metadata, self->_demuxer)
SGGet0Map(NSError *, close, self->_demuxer)
SGGet0Map(NSError *, seekable, self->_demuxer)

#pragma mark - Setter & Getter

- (CMTime)duration
{
    return self->_actual_time_range.duration;
}

- (NSArray<SGTrack *> *)tracks
{
    return [self->_tracks copy];
}

#pragma mark - Interface

- (NSError *)open
{
    NSError *ret = [self->_demuxer open];
    if (ret) {
        return ret;
    }
    CMTime start = CMTIME_IS_VALID(self->_timeRange.start) ? self->_timeRange.start : kCMTimeNegativeInfinity;
    CMTime duration = CMTIME_IS_VALID(self->_timeRange.duration) ? self->_timeRange.duration : kCMTimePositiveInfinity;
    self->_actual_time_range = CMTimeRangeGetIntersection(CMTimeRangeMake(start, duration),
                                                          CMTimeRangeMake(kCMTimeZero, self->_demuxer.duration));
    NSMutableArray<SGTrack *> *tracks = [NSMutableArray array];
    for (SGTrack *obj in self->_demuxer.tracks) {
        if ([self->_indexes containsObject:@(obj.index)]) {
            [tracks addObject:obj];
        }
    }
    self->_tracks = [tracks copy];
    self->_time_layout = [[SGTimeLayout alloc] initWithStart:CMTimeMultiply(self->_actual_time_range.start, -1)
                                                       scale:kCMTimeInvalid];
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    NSError *ret = [self->_demuxer seekToTime:CMTimeAdd(time, self->_actual_time_range.start)];
    if (ret) {
        return ret;
    }
    [self->_object_queue flush];
    self->_is_valid = 0;
    self->_is_start_output = 0;
    self->_is_end_output = 0;
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
        ret = [self->_demuxer nextPacket:&pkt];
        if (ret) {
            break;
        }
        if (![self->_indexes containsObject:@(pkt.track.index)]) {
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, self->_actual_time_range.start) < 0) {
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, CMTimeRangeGetEnd(self->_actual_time_range)) >= 0) {
            [pkt unlock];
            ret = SGECreateError(SGErrorCodeURLDemuxerFunnelFinished,
                                 SGOperationCodeURLDemuxerFunnelNext);
            break;
        }
        [pkt.codecDescription appendTimeLayout:self->_time_layout];
        [pkt.codecDescription appendTimeRange:self->_actual_time_range];
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
        if (self->_is_start_output) {
            [self->_object_queue getObjectAsync:&pkt];
            if (pkt) {
                [pkt.codecDescription appendTimeLayout:self->_time_layout];
                [pkt.codecDescription appendTimeRange:self->_actual_time_range];
                [pkt fill];
                *packet = pkt;
                break;
            }
        }
        if (self->_is_end_output) {
            ret = SGECreateError(SGErrorCodeURLDemuxerFunnelFinished,
                                 SGOperationCodeURLDemuxerFunnelNext);
            break;
        }
        ret = [self->_demuxer nextPacket:&pkt];
        if (ret) {
            self->_is_end_output = 1;
            continue;
        }
        if (![self->_indexes containsObject:@(pkt.track.index)]) {
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, self->_actual_time_range.start) < 0) {
            if (pkt.core->flags & AV_PKT_FLAG_KEY) {
                [self->_object_queue flush];
                self->_is_valid = 1;
            }
            if (self->_is_valid) {
                [self->_object_queue putObjectSync:pkt];
            }
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, CMTimeRangeGetEnd(self->_actual_time_range)) >= 0) {
            if (pkt.core->flags & AV_PKT_FLAG_KEY) {
                self->_is_end_output = 1;
            } else {
                [self->_object_queue putObjectSync:pkt];
            }
            [pkt unlock];
            continue;
        }
        if (!self->_is_start_output && pkt.core->flags & AV_PKT_FLAG_KEY) {
            [self->_object_queue flush];
        }
        self->_is_start_output = 1;
        [self->_object_queue putObjectSync:pkt];
        [pkt unlock];
        continue;
    }
    return ret;
}

@end
