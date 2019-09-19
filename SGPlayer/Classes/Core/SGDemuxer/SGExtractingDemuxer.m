//
//  SGExtractingDemuxer.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGExtractingDemuxer.h"
#import "SGPacket+Internal.h"
#import "SGObjectQueue.h"
#import "SGError.h"
#import "SGMacro.h"

@interface SGExtractingDemuxer ()

{
    struct {
        BOOL finished;
        BOOL inputting;
        BOOL outputting;
    } _flags;
}

@property (nonatomic, strong, readonly) SGTrack *track;
@property (nonatomic, strong, readonly) SGTimeLayout *scaleLayout;
@property (nonatomic, strong, readonly) SGTimeLayout *offsetLayout;
@property (nonatomic, strong, readonly) SGObjectQueue *packetQueue;

@end

@implementation SGExtractingDemuxer

@synthesize tracks = _tracks;
@synthesize duration = _duration;

- (instancetype)initWithDemuxable:(id<SGDemuxable>)demuxable index:(NSInteger)index timeRange:(CMTimeRange)timeRange scale:(CMTime)scale
{
    if (self = [super init]) {
        self->_overgop = YES;
        self->_scale = scale;
        self->_index = index;
        self->_demuxable = demuxable;
        self->_timeRange = SGCMTimeRangeFit(timeRange);
        self->_packetQueue = [[SGObjectQueue alloc] init];
    }
    return self;
}

#pragma mark - Mapping

SGGet0Map(id<SGDemuxableDelegate>, delegate, self->_demuxable)
SGSet1Map(void, setDelegate, id<SGDemuxableDelegate>, self->_demuxable)
SGGet0Map(SGDemuxerOptions *, options, self->_demuxable)
SGSet1Map(void, setOptions, SGDemuxerOptions *, self->_demuxable)
SGGet0Map(NSDictionary *, metadata, self->_demuxable)
SGGet0Map(NSError *, close, self->_demuxable)
SGGet0Map(NSError *, seekable, self->_demuxable)

#pragma mark - Control

- (NSError *)open
{
    NSError *error = [self->_demuxable open];
    if (error) {
        return error;
    }
    for (SGTrack *obj in self->_demuxable.tracks) {
        if (self->_index == obj.index) {
            self->_track = obj;
            self->_tracks = @[obj];
            break;
        }
    }
    CMTime start = CMTimeMaximum(self->_timeRange.start, kCMTimeZero);
    CMTime duration = CMTimeMinimum(self->_timeRange.duration, CMTimeSubtract(self->_demuxable.duration, start));
    self->_timeRange = CMTimeRangeMake(start, duration);
    self->_duration = SGCMTimeMultiply(duration, self->_scale);
    self->_scaleLayout = [[SGTimeLayout alloc] initWithScale:self->_scale];
    self->_offsetLayout = [[SGTimeLayout alloc] initWithOffset:CMTimeMultiply(start, -1)];
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    if (!CMTIME_IS_NUMERIC(time)) {
        return SGCreateError(SGErrorCodeInvlidTime, SGActionCodeFormatSeekFrame);
    }
    time = [self->_scaleLayout reconvertTimeStamp:time];
    time = [self->_offsetLayout reconvertTimeStamp:time];
    NSError *error = [self->_demuxable seekToTime:time];
    if (error) {
        return error;
    }
    [self->_packetQueue flush];
    self->_flags.finished = NO;
    self->_flags.inputting = NO;
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
    NSError *error = nil;
    while (YES) {
        SGPacket *pkt = nil;
        error = [self->_demuxable nextPacket:&pkt];
        if (error) {
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
            error = SGCreateError(SGErrorCodeURLDemuxerFunnelFinished, SGActionCodeURLDemuxerFunnelNext);
            break;
        }
        [pkt.codecDescriptor appendTimeLayout:self->_offsetLayout];
        [pkt.codecDescriptor appendTimeLayout:self->_scaleLayout];
        [pkt.codecDescriptor appendTimeRange:self->_timeRange];
        [pkt fill];
        *packet = pkt;
        break;
    }
    return error;
}

- (NSError *)nextPacketInternalOvergop:(SGPacket **)packet
{
    NSError *error = nil;
    while (YES) {
        SGPacket *pkt = nil;
        if (self->_flags.outputting) {
            [self->_packetQueue getObjectAsync:&pkt];
            if (pkt) {
                [pkt.codecDescriptor appendTimeLayout:self->_offsetLayout];
                [pkt.codecDescriptor appendTimeLayout:self->_scaleLayout];
                [pkt.codecDescriptor appendTimeRange:self->_timeRange];
                [pkt fill];
                *packet = pkt;
                break;
            }
        }
        if (self->_flags.finished) {
            error = SGCreateError(SGErrorCodeURLDemuxerFunnelFinished, SGActionCodeURLDemuxerFunnelNext);
            break;
        }
        error = [self->_demuxable nextPacket:&pkt];
        if (error) {
            if (error.code == SGErrorImmediateExitRequested) {
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
                self->_flags.inputting = YES;
            }
            if (self->_flags.inputting) {
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
    return error;
}

@end
