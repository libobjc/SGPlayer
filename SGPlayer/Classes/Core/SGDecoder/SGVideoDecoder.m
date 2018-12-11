//
//  SGVideoDecoder.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoDecoder.h"
#import "SGPacket+Internal.h"
#import "SGFrame+Internal.h"
#import "SGCodecContext.h"
#import "SGVideoFrame.h"

@interface SGVideoDecoder ()

{
    BOOL _alignment;
    CMTimeRange _timeRange;
    SGCodecContext *_codecContext;
    SGCodecDescription *_codecDescription;
}

@end

@implementation SGVideoDecoder

@synthesize index = _index;

- (void)setup
{
    self->_codecContext = [[SGCodecContext alloc] initWithTimebase:self->_codecDescription.timebase
                                                          codecpar:self->_codecDescription.codecpar
                                                        frameClass:[SGVideoFrame class]];
    [self->_codecContext open];
    self->_alignment = NO;
}

- (void)destroy
{
    [self->_codecContext close];
    self->_codecContext = nil;
    self->_alignment = NO;
}

#pragma mark - Control

- (void)flush
{
    [self->_codecContext flush];
}

- (NSArray<__kindof SGFrame *> *)decode:(SGPacket *)packet
{
    NSMutableArray *ret = [NSMutableArray array];
    SGCodecDescription *codecDescription = packet.codecDescription;
    if (codecDescription && ![codecDescription isEqualToDescription:self->_codecDescription]) {
        NSArray<SGFrame *> *objs = [self processPacket:nil];
        for (SGFrame *obj in objs) {
            [ret addObject:obj];
        }
        codecDescription = [codecDescription copy];
        self->_codecDescription = codecDescription;
        self->_timeRange = codecDescription.finalTimeRange;
        [self destroy];
        [self setup];
    }
    NSArray<SGFrame *> *objs = [self processPacket:packet];
    for (SGFrame *obj in objs) {
        [ret addObject:obj];
    }
    return ret;
}

- (NSArray<__kindof SGFrame *> *)finish
{
    return [self processPacket:nil];
}

#pragma mark - Process

- (NSArray<__kindof SGFrame *> *)processPacket:(SGPacket *)packet
{
    if (!self->_codecContext || !self->_codecDescription) {
        return nil;
    }
    NSArray *objs = [self->_codecContext decode:packet];
    return [self processFrames:objs];
}

- (NSArray<__kindof SGFrame *> *)processFrames:(NSArray<SGFrame *> *)frames
{
    NSMutableArray *ret = [NSMutableArray array];
    for (SGFrame *obj in frames) {
        SGCodecDescription *codecDescription = [self->_codecDescription copy];
        [obj setCodecDescription:codecDescription];
        [obj fill];
        if (CMTimeCompare(obj.timeStamp, self->_timeRange.start) < 0) {
            [obj unlock];
            continue;
        }
        if (CMTimeCompare(obj.timeStamp, CMTimeRangeGetEnd(self->_timeRange)) >= 0) {
            [obj unlock];
            continue;
        }
        if (!self->_alignment) {
            self->_alignment = YES;
            CMTime start = self->_timeRange.start;
            CMTime duration = CMTimeSubtract(CMTimeAdd(obj.timeStamp, obj.duration), start);
            CMTimeScale timescale = duration.timescale;
            if (CMTimeCompare(obj.timeStamp, start) > 0) {
                obj.core->pts = av_rescale(timescale, start.value, start.timescale);
                obj.core->pkt_dts = av_rescale(timescale, start.value, start.timescale);
                obj.core->pkt_duration = av_rescale(timescale, duration.value, duration.timescale);
                obj.core->best_effort_timestamp = av_rescale(timescale, start.value, start.timescale);
                SGCodecDescription *codecDescription = [[SGCodecDescription alloc] init];
                codecDescription.track = obj.track;
                codecDescription.timebase = av_make_q(1, timescale);
                [obj setCodecDescription:codecDescription];
                [obj fill];
            }
        }
        if (YES) {
            CMTime start = obj.timeStamp;
            CMTime duration = CMTimeSubtract(CMTimeRangeGetEnd(self->_timeRange), obj.timeStamp);
            CMTimeScale timescale = duration.timescale;
            if (CMTimeCompare(obj.duration, duration) > 0) {
                obj.core->pts = av_rescale(timescale, start.value, start.timescale);
                obj.core->pkt_dts = av_rescale(timescale, start.value, start.timescale);
                obj.core->pkt_duration = av_rescale(timescale, duration.value, duration.timescale);
                obj.core->best_effort_timestamp = av_rescale(timescale, start.value, start.timescale);
                SGCodecDescription *codecDescription = [[SGCodecDescription alloc] init];
                codecDescription.track = obj.track;
                codecDescription.timebase = av_make_q(1, timescale);
                [obj setCodecDescription:codecDescription];
                [obj fill];
            }
        }
        [ret addObject:obj];
    }
    return ret;
}

@end
