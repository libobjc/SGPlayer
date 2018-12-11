//
//  SGAudioDecoder.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioDecoder.h"
#import "SGPacket+Internal.h"
#import "SGAudioFrame+Internal.h"
#import "SGCodecContext.h"
#import "SGAudioFrame.h"

@interface SGAudioDecoder ()

{
    BOOL _alignment;
    CMTimeRange _timeRange;
    SGCodecContext *_codecContext;
    SGCodecDescription *_codecDescription;
}

@end

@implementation SGAudioDecoder

@synthesize index = _index;

- (void)setup
{
    SGCodecDescription *cd = self->_codecDescription;
    self->_codecContext = [[SGCodecContext alloc] initWithTimebase:cd.timebase codecpar:cd.codecpar frameClass:[SGAudioFrame class]];
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
    SGCodecDescription *cd = packet.codecDescription;
    if (cd && ![cd isEqualToDescription:self->_codecDescription]) {
        NSArray<SGFrame *> *objs = [self finish];
        for (SGFrame *obj in objs) {
            [ret addObject:obj];
        }
        cd = [cd copy];
        self->_codecDescription = cd;
        self->_timeRange = cd.finalTimeRange;
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
    for (SGAudioFrame *obj in frames) {
        obj.codecDescription = self->_codecDescription;
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
            CMTime duration = CMTimeSubtract(obj.timeStamp, self->_timeRange.start);
            if (CMTimeCompare(duration, kCMTimeZero) > 0) {
                SGAudioDescription *description = obj.audioDescription;
                int sampleRate = description.sampleRate;
                int numberOfSamples = CMTimeGetSeconds(CMTimeMultiply(duration, sampleRate));
                SGAudioFrame *temp = [SGAudioFrame audioFrameWithDescription:description numberOfSamples:numberOfSamples];
                temp.core->pts = av_rescale(sampleRate, self->_timeRange.start.value, self->_timeRange.start.timescale);
                temp.core->pkt_dts = av_rescale(sampleRate, self->_timeRange.start.value, self->_timeRange.start.timescale);
                temp.core->pkt_size = 1;
                temp.core->pkt_duration = av_rescale(sampleRate, duration.value, duration.timescale);
                temp.core->best_effort_timestamp = av_rescale(sampleRate, self->_timeRange.start.value, self->_timeRange.start.timescale);
                SGCodecDescription *cd = [[SGCodecDescription alloc] init];
                cd.track = obj.track;
                cd.timebase = av_make_q(1, sampleRate);
                [temp setCodecDescription:cd];
                [temp fill];
                [ret addObject:temp];
            }
        }
        [ret addObject:obj];
    }
    return ret;
}

@end
