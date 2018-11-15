//
//  SGURLDemuxerFunnel.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGURLDemuxerFunnel.h"
#import "SGURLDemuxer.h"
#import "SGError.h"
#import "SGMacro.h"

@interface SGURLDemuxerFunnel ()

@property (nonatomic, strong) SGURLDemuxer * demuxer;
@property (nonatomic, copy) NSArray <SGTrack *> * tracks;
@property (nonatomic, copy) NSArray <SGTrack *> * audioTracks;
@property (nonatomic, copy) NSArray <SGTrack *> * videoTracks;
@property (nonatomic, copy) NSArray <SGTrack *> * otherTracks;
@property (nonatomic) CMTimeRange actualTimeRange;

@end

@implementation SGURLDemuxerFunnel

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        self.demuxer = [[SGURLDemuxer alloc] initWithURL:URL];
    }
    return self;
}

SGGet0Map(id <SGDemuxableDelegate>, delegate, self.demuxer)
SGSet1Map(void, setDelegate, id <SGDemuxableDelegate>, self.demuxer)
SGGet0Map(NSDictionary *, options, self.demuxer)
SGSet1Map(void, setOptions, NSDictionary *, self.demuxer)
SGGet0Map(CMTime, duration, self.actualTimeRange)
SGGet0Map(NSError *, seekable, self.demuxer)
SGGet0Map(NSDictionary *, metadata, self.demuxer)
SGGet0Map(NSError *, close, self.demuxer)

- (NSError *)open
{
    NSError * ret = [self.demuxer open];
    if (ret) {
        return ret;
    }
    CMTime start = CMTIME_IS_VALID(self.desireTimeRange.start) ? self.desireTimeRange.start : kCMTimeNegativeInfinity;
    CMTime duration = CMTIME_IS_VALID(self.desireTimeRange.duration) ? self.desireTimeRange.duration : kCMTimePositiveInfinity;
    self.actualTimeRange = CMTimeRangeGetIntersection(CMTimeRangeMake(start, duration),
                                                      CMTimeRangeMake(kCMTimeZero, self.demuxer.duration));
    NSMutableArray <SGTrack *> * tracks = [NSMutableArray array];
    NSMutableArray <SGTrack *> * audioTracks = [NSMutableArray array];
    NSMutableArray <SGTrack *> * videoTracks = [NSMutableArray array];
    NSMutableArray <SGTrack *> * otherTracks = [NSMutableArray array];
    for (SGTrack * obj in self.demuxer.tracks) {
        if ([self.desireIndexes containsObject:@(obj.index)]) {
            [tracks addObject:obj];
        }
    }
    for (SGTrack * obj in self.demuxer.audioTracks) {
        if ([self.desireIndexes containsObject:@(obj.index)]) {
            [audioTracks addObject:obj];
        }
    }
    for (SGTrack * obj in self.demuxer.videoTracks) {
        if ([self.desireIndexes containsObject:@(obj.index)]) {
            [videoTracks addObject:obj];
        }
    }
    for (SGTrack * obj in self.demuxer.otherTracks) {
        if ([self.desireIndexes containsObject:@(obj.index)]) {
            [otherTracks addObject:obj];
        }
    }
    self.tracks = [tracks copy];
    self.audioTracks = [audioTracks copy];
    self.videoTracks = [videoTracks copy];
    self.otherTracks = [otherTracks copy];
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    return [self seekToTime:CMTimeAdd(time, self.actualTimeRange.start)];
}

- (NSError *)nextPacket:(SGPacket *)packet
{
    NSError * ret = nil;
    while (YES) {
        ret = [self.demuxer nextPacket:packet];
        if (ret) {
            break;
        }
        if (CMTimeCompare(packet.timeStamp, self.actualTimeRange.start) < 0) {
            [packet clear];
            continue;
        }
        if (CMTimeCompare(packet.timeStamp, CMTimeRangeGetEnd(self.actualTimeRange)) >= 0) {
            [packet clear];
            ret = SGECreateError(SGErrorCodeURLDemuxerFunnelFinished,
                                 SGOperationCodeURLDemuxerFunnelNext);
            break;
        }
        break;
    }
    return ret;
}

@end
