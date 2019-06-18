//
//  SGPaddingDemuxer.m
//  SGPlayer
//
//  Created by Single on 2019/6/4.
//  Copyright © 2019 single. All rights reserved.
//

#import "SGPaddingDemuxer.h"
#import "SGPacket+Internal.h"
#import "SGObjectPool.h"
#import "SGError.h"

@interface SGPaddingDemuxer ()

@property (nonatomic, readonly) CMTime basetime;
@property (nonatomic, readonly) CMTime lasttime;

@end

@implementation SGPaddingDemuxer

@synthesize tracks = _tracks;
@synthesize options = _options;
@synthesize delegate = _delegate;
@synthesize metadata = _metadata;
@synthesize duration = _duration;

- (instancetype)initWithDuration:(CMTime)duration
{
    if (self = [super init]) {
        self->_duration = duration;
        [self seekToTime:kCMTimeZero];
    }
    return self;
}

#pragma mark - Control

- (NSError *)open
{
    return nil;
}

- (NSError *)close
{
    return nil;
}

- (NSError *)seekable
{
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    if (!CMTIME_IS_NUMERIC(time)) {
        return SGECreateError(SGErrorCodeInvlidTime, SGOperationCodeFormatSeekFrame);
    }
    time = CMTimeMaximum(time, kCMTimeZero);
    time = CMTimeMinimum(time, self->_duration);
    self->_basetime = time;
    self->_lasttime = time;
    return nil;
}

- (NSError *)nextPacket:(SGPacket **)packet
{
    if (CMTimeCompare(self->_lasttime, self->_duration) >= 0) {
        return SGECreateError(SGErrorCodeDemuxerEndOfFile, SGOperationCodeFormatReadFrame);
    }
    CMTime timeStamp = self->_lasttime;
    CMTime duration = CMTimeSubtract(self->_duration, self->_lasttime);
    SGPacket *pkt = [[SGObjectPool sharedPool] objectWithClass:[SGPacket class] reuseName:[SGPacket commonReuseName]];
    pkt.core->size = 1;
    pkt.core->pts = av_rescale(AV_TIME_BASE, timeStamp.value, timeStamp.timescale);
    pkt.core->dts = av_rescale(AV_TIME_BASE, timeStamp.value, timeStamp.timescale);
    pkt.core->duration = av_rescale(AV_TIME_BASE, duration.value, duration.timescale);
    SGCodecDescription *cd = [[SGCodecDescription alloc] init];
    cd.type = SGCodecType_Padding;
    cd.timebase = AV_TIME_BASE_Q;
    [pkt setCodecDescription:cd];
    [pkt fill];
    *packet = pkt;
    self->_lasttime = self->_duration;
    return nil;
}

@end
