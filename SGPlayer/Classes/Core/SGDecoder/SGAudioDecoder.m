//
//  SGAudioDecoder.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioDecoder.h"
#import "SGPacket+Internal.h"
#import "SGFrame+Internal.h"
#import "SGCodecContext.h"
#import "SGAudioFrame.h"

@interface SGAudioDecoder ()

{
    BOOL _alignment;
    SGCodecContext *_codecContext;
    SGCodecDescription *_codecDescription;
}

@end

@implementation SGAudioDecoder

@synthesize index = _index;

- (void)setup
{
    self->_alignment = NO;
    self->_codecContext = [[SGCodecContext alloc] initWithTimebase:self->_codecDescription.timebase
                                                          codecpar:self->_codecDescription.codecpar
                                                        frameClass:[SGAudioFrame class]];
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
        NSArray<SGFrame *> *objs = [self finish];
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
    for (SGAudioFrame *obj in frames) {
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
            CMTime duration = CMTimeSubtract(obj.timeStamp, start);
            CMTimeScale timescale = duration.timescale;
            SGAudioDescription *description = obj.audioDescription;
            int numberOfSamples = CMTimeGetSeconds(CMTimeMultiply(duration, description.sampleRate));
            if (numberOfSamples > 0) {
                SGAudioFrame *temp = [SGAudioFrame audioFrameWithDescription:description numberOfSamples:numberOfSamples];
                temp.core->pts = av_rescale(timescale, start.value, start.timescale);
                temp.core->pkt_dts = av_rescale(timescale, start.value, start.timescale);
                temp.core->pkt_size = 1;
                temp.core->pkt_duration = av_rescale(timescale, duration.value, duration.timescale);
                temp.core->best_effort_timestamp = av_rescale(timescale, start.value, start.timescale);
                SGCodecDescription *codecDescription = [[SGCodecDescription alloc] init];
                codecDescription.track = obj.track;
                codecDescription.timebase = av_make_q(1, timescale);
                [temp setCodecDescription:codecDescription];
                [temp fill];
                [ret addObject:temp];
            }
        }
        if (YES) {
            CMTime start = obj.timeStamp;
            CMTime duration = CMTimeSubtract(CMTimeRangeGetEnd(codecDescription.timeRange), obj.timeStamp);
            CMTimeScale timescale = duration.timescale;
            SGAudioDescription *description = obj.audioDescription;
            int numberOfSamples = CMTimeGetSeconds(CMTimeMultiply(duration, description.sampleRate));
            if (numberOfSamples < obj.numberOfSamples) {
                SGAudioFrame *temp = [SGAudioFrame audioFrameWithDescription:description numberOfSamples:numberOfSamples];
                temp.core->pts = av_rescale(timescale, start.value, start.timescale);
                temp.core->pkt_dts = av_rescale(timescale, start.value, start.timescale);
                temp.core->pkt_size = 1;
                temp.core->pkt_duration = av_rescale(timescale, duration.value, duration.timescale);
                temp.core->best_effort_timestamp = av_rescale(timescale, start.value, start.timescale);
                for (int i = 0; i < description.numberOfPlanes; i++) {
                    memcpy(temp.core->data[i], obj.core->data[i], temp.core->linesize[i]);
                }
                SGCodecDescription *codecDescription = [[SGCodecDescription alloc] init];
                codecDescription.track = obj.track;
                codecDescription.timebase = av_make_q(1, timescale);
                [temp setCodecDescription:codecDescription];
                [temp fill];
                [ret addObject:temp];
                [obj unlock];
                continue;
            }
        }
        [ret addObject:obj];
    }
    return ret;
}

@end
