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
    SGCodecContext *_codecContext;
    SGCodecDescription *_codecDescription;
}

@end

@implementation SGVideoDecoder

- (void)setup
{
    self->_alignment = NO;
    self->_codecContext = [[SGCodecContext alloc] initWithTimebase:self->_codecDescription.timebase
                                                          codecpar:self->_codecDescription.codecpar
                                                        frameClass:[SGVideoFrame class]];
    [self->_codecContext open];
}

- (void)destroy
{
    self->_alignment = NO;
    [self->_codecContext close];
    self->_codecContext = nil;
}

#pragma mark - Control

- (void)flush
{
    self->_alignment = NO;
    [self->_codecContext flush];
}

- (NSArray<__kindof SGFrame *> *)decode:(SGPacket *)packet
{
    NSMutableArray *ret = [NSMutableArray array];
    SGCodecDescription *codecDescription = packet.codecDescription;
    NSAssert(codecDescription, @"Invalid Codec Description.");
    if (![codecDescription isEqualCodecparToDescription:self->_codecDescription]) {
        NSArray<SGFrame *> *objs = [self processPacket:nil];
        for (SGFrame *obj in objs) {
            [ret addObject:obj];
        }
        self->_codecDescription = [codecDescription copy];
        [self destroy];
        [self setup];
    }
    [codecDescription fillToDescription:self->_codecDescription];
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
        if (CMTimeCompare(obj.timeStamp, codecDescription.timeRange.start) < 0) {
            [obj unlock];
            continue;
        }
        if (CMTimeCompare(obj.timeStamp, CMTimeRangeGetEnd(codecDescription.timeRange)) >= 0) {
            [obj unlock];
            continue;
        }
        if (!self->_alignment) {
            self->_alignment = YES;
            CMTime start = codecDescription.timeRange.start;
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
            CMTime duration = CMTimeSubtract(CMTimeRangeGetEnd(codecDescription.timeRange), obj.timeStamp);
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
