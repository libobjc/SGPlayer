//
//  SGAudioMixer.m
//  SGPlayer
//
//  Created by Single on 2018/11/29.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioMixer.h"
#import "SGAudioFrame+Internal.h"
#import "SGAudioMixerUnit.h"

@interface SGAudioMixer ()

{
    CMTime _startTime;
    NSDictionary<NSNumber *, SGAudioMixerUnit *> *_units;
}

@end

@implementation SGAudioMixer

- (instancetype)initWithAudioDescription:(SGAudioDescription *)audioDescription tracks:(NSArray<SGTrack *> *)tracks
{
    if (self = [super init]) {
        self->_tracks = [tracks copy];
        self->_audioDescription = [audioDescription copy];
        
        NSMutableDictionary *units = [NSMutableDictionary dictionary];
        for (SGTrack *obj in self->_tracks) {
            [units setObject:[[SGAudioMixerUnit alloc] init] forKey:@(obj.index)];
        }
        self->_units = [units copy];
        self->_startTime = kCMTimeNegativeInfinity;
        [self setWeights:nil];
    }
    return self;
}

#pragma mark - Setter & Getter

- (void)setWeights:(NSArray<NSNumber *> *)weights
{
    if (weights.count != self->_tracks.count) {
        NSMutableArray *obj = [NSMutableArray array];
        double weight = 1.0 / self->_tracks.count;
        for (int i = 0; i < self->_tracks.count; i++) {
            [obj addObject:@(weight)];
        }
        self->_weights = [obj copy];
    } else {
        double sum = 0;
        for (NSNumber *obj in weights) {
            sum += obj.doubleValue;
        }
        NSMutableArray *obj = [NSMutableArray array];
        for (int i = 0; i < self->_tracks.count; i++) {
            double value = [weights objectAtIndex:i].doubleValue;
            [obj addObject:@(value / sum)];
        }
        self->_weights = [obj copy];
    }
}

#pragma mark - Control

- (SGAudioFrame *)putFrame:(SGAudioFrame *)frame
{
    if (self->_tracks.count <= 1) {
        return frame;
    }
    if (CMTimeCompare(frame.timeStamp, self->_startTime) < 0) {
        [frame unlock];
        return nil;
    }
    NSAssert([self->_audioDescription isEqualToDescription:frame.audioDescription], @"Invalid Format.");
    NSAssert(self->_audioDescription.format == AV_SAMPLE_FMT_FLTP, @"Invalid Format.");
    SGAudioMixerUnit *unit = [self->_units objectForKey:@(frame.track.index)];
    BOOL ret = [unit putFrame:frame];
    [frame unlock];
    if (ret) {
        return [self mixForPutFrame];
    }
    return nil;
}

- (SGAudioFrame *)finish
{
    if (self->_tracks.count <= 1) {
        return nil;
    }
    return [self mixForFinish];
}

- (SGCapacity *)capacity
{
    SGCapacity *capacity = [[SGCapacity alloc] init];
    for (SGAudioMixerUnit *obj in self->_units.allValues) {
        capacity = [capacity maximum:obj.capacity];
    }
    return capacity;
}

- (void)flush
{
    for (SGAudioMixerUnit *obj in self->_units.allValues) {
        [obj flush];
    }
    self->_startTime = kCMTimeNegativeInfinity;
}

#pragma mark - Mix

- (SGAudioFrame *)mixForPutFrame
{
    CMTime start = kCMTimePositiveInfinity;
    CMTime end = kCMTimePositiveInfinity;
    CMTime maximumDuration = kCMTimeZero;
    for (SGAudioMixerUnit *obj in self->_units.allValues) {
        if (CMTIMERANGE_IS_INVALID(obj.timeRange)) {
            continue;
        }
        start = CMTimeMinimum(start, obj.timeRange.start);
        start = CMTimeMaximum(start, self->_startTime);
        end = CMTimeMinimum(end, CMTimeRangeGetEnd(obj.timeRange));
        maximumDuration = CMTimeMaximum(maximumDuration, obj.timeRange.duration);
    }
    if (CMTimeCompare(maximumDuration, CMTimeMake(8, 100)) < 0) {
        return nil;
    }
    return [self mixWithRange:CMTimeRangeMake(start, CMTimeSubtract(end, start))];
}

- (SGAudioFrame *)mixForFinish
{
    CMTime start = kCMTimePositiveInfinity;
    CMTime end = kCMTimeNegativeInfinity;
    for (SGAudioMixerUnit *obj in self->_units.allValues) {
        if (CMTIMERANGE_IS_INVALID(obj.timeRange)) {
            continue;
        }
        start = CMTimeMinimum(start, obj.timeRange.start);
        start = CMTimeMaximum(start, self->_startTime);
        end = CMTimeMaximum(end, CMTimeRangeGetEnd(obj.timeRange));
    }
    if (CMTimeCompare(CMTimeSubtract(end, start), kCMTimeZero) <= 0) {
        return nil;
    }
    return [self mixWithRange:CMTimeRangeMake(start, CMTimeSubtract(end, start))];
}

- (SGAudioFrame *)mixWithRange:(CMTimeRange)range
{
    if (CMTIMERANGE_IS_INVALID(range)) {
        return nil;
    }
    self->_startTime = CMTimeRangeGetEnd(range);
    
    CMTime start = range.start;
    CMTime duration = range.duration;
    CMTimeScale timescale = duration.timescale;
    SGAudioDescription *description = self->_audioDescription;
    int numberOfSamples = CMTimeGetSeconds(CMTimeMultiply(duration, description.sampleRate));
    SGAudioFrame *ret = [SGAudioFrame audioFrameWithDescription:description numberOfSamples:numberOfSamples];
    ret.core->pts = av_rescale(timescale, start.value, start.timescale);
    ret.core->pkt_dts = av_rescale(timescale, start.value, start.timescale);
    ret.core->pkt_size = 1;
    ret.core->pkt_duration = av_rescale(timescale, duration.value, duration.timescale);
    ret.core->best_effort_timestamp = av_rescale(timescale, start.value, start.timescale);
    NSMutableDictionary *list = [NSMutableDictionary dictionary];
    for (SGTrack *obj in self->_tracks) {
        NSArray *frames = [self->_units[@(obj.index)] framesToEndTime:CMTimeRangeGetEnd(range)];
        if (frames.count > 0) {
            [list setObject:frames forKey:@(obj.index)];
        }
    }
    for (int i = 0; i < numberOfSamples; i++) {
        for (int j = 0; j < self->_tracks.count; j++) {
            for (SGAudioFrame *obj in list[@(self->_tracks[j].index)]) {
                int c = CMTimeGetSeconds(CMTimeMultiply(CMTimeSubtract(obj.timeStamp, start), description.sampleRate));
                if (i < c) {
                    break;
                }
                if (i >= c + obj.numberOfSamples) {
                    continue;
                }
                for (int k = 0; k < description.numberOfPlanes; k++) {
                    ((float *)ret.core->data[k])[i] += (((float *)obj.data[k])[i - c] * self->_weights[j].floatValue);
                }
                break;
            }
        }
    }
    for (NSArray *objs in list.allValues) {
        for (SGAudioFrame *obj in objs) {
            [obj unlock];
        }
    }
    SGCodecDescription *cd = [[SGCodecDescription alloc] init];
    cd.timebase = av_make_q(1, timescale);
    [ret setCodecDescription:cd];
    [ret fill];
    return ret;
}

@end
