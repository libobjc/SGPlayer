//
//  SGURLDemuxerFunnel.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGURLDemuxerFunnel.h"
#import "SGURLDemuxer.h"
#import "SGPacket+Internal.h"
#import "SGError.h"
#import "SGMacro.h"

@interface SGURLDemuxerFunnel ()

@property (nonatomic, strong) SGURLDemuxer * demuxer;
@property (nonatomic, strong) SGTimeLayout * timeLayout;
@property (nonatomic, copy) NSArray <SGTrack *> * tracks;
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
    for (SGTrack * obj in self.demuxer.tracks) {
        if ([self.desireIndexes containsObject:@(obj.index)]) {
            [tracks addObject:obj];
        }
    }
    self.tracks = [tracks copy];
    self.timeLayout = [[SGTimeLayout alloc] initWithStart:CMTimeMultiply(self.actualTimeRange.start, -1) scale:kCMTimeInvalid];
    return nil;
}

SGGet0Map(NSError *, seekable, self.demuxer)

- (NSError *)seekToTime:(CMTime)time
{
    return [self.demuxer seekToTime:CMTimeAdd(time, self.actualTimeRange.start)];
}

- (NSError *)nextPacket:(SGPacket *)packet
{
    NSError * ret = nil;
    while (YES) {
        ret = [self.demuxer nextPacket:packet];
        if (ret) {
            break;
        }
        if (![self.desireIndexes containsObject:@(packet.index)]) {
            [packet clear];
            continue;
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
        [packet setTimeLayout:self.timeLayout];
        break;
    }
    return ret;
}

@end
