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
    int32_t _is_queue_valid;
    int32_t _is_queue_start_output;
    int32_t _is_queue_end_output;
}

@property (nonatomic, strong) SGURLDemuxer * demuxer;
@property (nonatomic, strong) SGTimeLayout * timeLayout;
@property (nonatomic, strong) SGObjectQueue * objectQueue;
@property (nonatomic, copy) NSArray <SGTrack *> * tracks;
@property (nonatomic) CMTimeRange actualTimeRange;

@end

@implementation SGURLDemuxerFunnel

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        self.demuxer = [[SGURLDemuxer alloc] initWithURL:URL];
        self.objectQueue = [[SGObjectQueue alloc] init];
        self.overgop = YES;
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

#pragma mark - Mapping

SGGet0Map(id <SGDemuxableDelegate>, delegate, self.demuxer)
SGSet1Map(void, setDelegate, id <SGDemuxableDelegate>, self.demuxer)
SGGet0Map(NSDictionary *, options, self.demuxer)
SGSet1Map(void, setOptions, NSDictionary *, self.demuxer)
SGGet0Map(CMTime, duration, self.actualTimeRange)
SGGet0Map(NSDictionary *, metadata, self.demuxer)
SGGet0Map(NSError *, close, self.demuxer)
SGGet0Map(NSError *, seekable, self.demuxer)

#pragma mark - Interface

- (NSError *)open
{
    NSError * ret = [self.demuxer open];
    if (ret) {
        return ret;
    }
    CMTime start = CMTIME_IS_VALID(self.timeRange.start) ? self.timeRange.start : kCMTimeNegativeInfinity;
    CMTime duration = CMTIME_IS_VALID(self.timeRange.duration) ? self.timeRange.duration : kCMTimePositiveInfinity;
    self.actualTimeRange = CMTimeRangeGetIntersection(CMTimeRangeMake(start, duration),
                                                      CMTimeRangeMake(kCMTimeZero, self.demuxer.duration));
    NSMutableArray <SGTrack *> * tracks = [NSMutableArray array];
    for (SGTrack * obj in self.demuxer.tracks) {
        if ([self.indexes containsObject:@(obj.index)]) {
            [tracks addObject:obj];
        }
    }
    self.tracks = [tracks copy];
    self.timeLayout = [[SGTimeLayout alloc] initWithStart:CMTimeMultiply(self.actualTimeRange.start, -1) scale:kCMTimeInvalid];
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    NSError * ret = [self.demuxer seekToTime:CMTimeAdd(time, self.actualTimeRange.start)];
    if (ret) {
        return ret;
    }
    [self.objectQueue flush];
    self->_is_queue_valid = 0;
    self->_is_queue_start_output = 0;
    self->_is_queue_end_output = 0;
    return nil;
}

- (NSError *)nextPacket:(SGPacket **)packet
{
    if (!self.overgop) {
        return [self nextPacketInternal:packet];
    }
    return [self nextPacketInternalOvergop:packet];
}

- (NSError *)nextPacketInternal:(SGPacket **)packet
{
    NSError * ret = nil;
    while (YES) {
        SGPacket * pkt = nil;
        ret = [self.demuxer nextPacket:&pkt];
        if (ret) {
            break;
        }
        if (![self.indexes containsObject:@(pkt.track.index)]) {
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, self.actualTimeRange.start) < 0) {
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, CMTimeRangeGetEnd(self.actualTimeRange)) >= 0) {
            [pkt unlock];
            ret = SGECreateError(SGErrorCodeURLDemuxerFunnelFinished,
                                 SGOperationCodeURLDemuxerFunnelNext);
            break;
        }
        [pkt.codecDescription appendTimeLayout:self.timeLayout];
        [pkt.codecDescription appendTimeRange:self.actualTimeRange];
        [pkt fill];
        * packet = pkt;
        break;
    }
    return ret;
}

- (NSError *)nextPacketInternalOvergop:(SGPacket **)packet
{
    NSError * ret = nil;
    while (YES) {
        SGPacket * pkt = nil;
        if (self->_is_queue_start_output) {
            [self.objectQueue getObjectAsync:&pkt];
            if (pkt) {
                [pkt.codecDescription appendTimeLayout:self.timeLayout];
                [pkt.codecDescription appendTimeRange:self.actualTimeRange];
                [pkt fill];
                *packet = pkt;
                break;
            }
        }
        if (self->_is_queue_end_output) {
            ret = SGECreateError(SGErrorCodeURLDemuxerFunnelFinished,
                                 SGOperationCodeURLDemuxerFunnelNext);
            break;
        }
        ret = [self.demuxer nextPacket:&pkt];
        if (ret) {
            self->_is_queue_end_output = 1;
            continue;
        }
        if (![self.indexes containsObject:@(pkt.track.index)]) {
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, self.actualTimeRange.start) < 0) {
            if (pkt.core->flags & AV_PKT_FLAG_KEY) {
                [self.objectQueue flush];
                self->_is_queue_valid = 1;
            }
            if (self->_is_queue_valid) {
                [self.objectQueue putObjectSync:pkt];
            }
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, CMTimeRangeGetEnd(self.actualTimeRange)) >= 0) {
            if (pkt.core->flags & AV_PKT_FLAG_KEY) {
                self->_is_queue_end_output = 1;
            } else {
                [self.objectQueue putObjectSync:pkt];
            }
            [pkt unlock];
            continue;
        }
        if (!self->_is_queue_start_output && pkt.core->flags & AV_PKT_FLAG_KEY) {
            [self.objectQueue flush];
        }
        self->_is_queue_start_output = 1;
        [self.objectQueue putObjectSync:pkt];
        [pkt unlock];
        continue;
    }
    return ret;
}

@end
