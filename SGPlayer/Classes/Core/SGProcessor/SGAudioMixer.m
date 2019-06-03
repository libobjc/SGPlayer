//
//  SGAudioMixer.m
//  SGPlayer
//
//  Created by Single on 2018/11/29.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioMixer.h"
#import "SGFrame+Internal.h"
#import "SGAudioMixerUnit.h"

@interface SGAudioMixer ()

@property (nonatomic, readonly) CMTime startTime;
@property (nonatomic, strong, readonly) NSDictionary<NSNumber *, SGAudioMixerUnit *> *units;

@end

@implementation SGAudioMixer

- (instancetype)initWithTracks:(NSArray<SGTrack *> *)tracks
                       weights:(NSArray<NSNumber *> *)weights
              audioDescription:(SGAudioDescription *)audioDescription

{
    if (self = [super init]) {
        self->_tracks = [tracks copy];
        self->_weights = [weights copy];
        self->_audioDescription = [audioDescription copy];
        self->_startTime = kCMTimeNegativeInfinity;
        NSMutableDictionary *units = [NSMutableDictionary dictionary];
        for (SGTrack *obj in self->_tracks) {
            [units setObject:[[SGAudioMixerUnit alloc] init] forKey:@(obj.index)];
        }
        self->_units = [units copy];
    }
    return self;
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
    
    NSArray<NSNumber *> *weights = self->_weights;
    if (weights.count != self->_tracks.count) {
        NSMutableArray *obj = [NSMutableArray array];
        for (int i = 0; i < self->_tracks.count; i++) {
            [obj addObject:@(1.0 / self->_tracks.count)];
        }
        weights = [obj copy];
    } else {
        double sum = 0;
        for (NSNumber *obj in weights) {
            sum += obj.doubleValue;
        }
        NSMutableArray *obj = [NSMutableArray array];
        for (int i = 0; i < self->_tracks.count; i++) {
            [obj addObject:@(weights[i].doubleValue / sum)];
        }
        weights = [obj copy];
    }
    
    CMTime start = range.start;
    CMTime duration = range.duration;
    SGAudioDescription *description = self->_audioDescription;
    int numberOfSamples = CMTimeGetSeconds(CMTimeMultiply(duration, description.sampleRate));
    SGAudioFrame *ret = [SGAudioFrame audioFrameWithDescription:description numberOfSamples:numberOfSamples];
    NSMutableDictionary *list = [NSMutableDictionary dictionary];
    for (SGTrack *obj in self->_tracks) {
        NSArray *frames = [self->_units[@(obj.index)] framesToEndTime:CMTimeRangeGetEnd(range)];
        if (frames.count > 0) {
            [list setObject:frames forKey:@(obj.index)];
        }
    }
    NSMutableArray *discontinuous = [NSMutableArray array];
    for (int t = 0; t < self->_tracks.count; t++) {
        int lastEE = 0;
        for (SGAudioFrame *obj in list[@(self->_tracks[t].index)]) {
            int s = CMTimeGetSeconds(CMTimeMultiply(CMTimeSubtract(obj.timeStamp, start), description.sampleRate));
            int e = s + obj.numberOfSamples;
            int ss = MAX(0, s);
            int ee = MIN(numberOfSamples, e);
            if (ss - lastEE != 0) {
                NSRange range = NSMakeRange(MIN(ss, lastEE), ABS(ss - lastEE));
                [discontinuous addObject:[NSValue valueWithRange:range]];
            }
            lastEE = ee;
            for (int i = ss; i < ee; i++) {
                for (int c = 0; c < description.numberOfPlanes; c++) {
                    ((float *)ret.core->data[c])[i] += (((float *)obj.data[c])[i - s] * weights[t].floatValue);
                }
            }
        }
    }
    for (NSValue *obj in discontinuous) {
        NSRange range = obj.rangeValue;
        for (int c = 0; c < description.numberOfPlanes; c++) {
            float value = 0;
            if (range.location > 0) {
                value += ((float *)ret.core->data[c])[range.location - 1] * 0.5;
            }
            if (NSMaxRange(range) < numberOfSamples - 1) {
                value += ((float *)ret.core->data[c])[NSMaxRange(range)] * 0.5;
            }
            for (int i = (int)range.location; i < NSMaxRange(range); i++) {
                ((float *)ret.core->data[c])[i] = value;
            }
        }
    }
    for (NSArray *objs in list.allValues) {
        for (SGAudioFrame *obj in objs) {
            [obj unlock];
        }
    }
    [ret setCodecDescription:[[SGCodecDescription alloc] init]];
    [ret fillWithDuration:duration timeStamp:start decodeTimeStamp:start];
    return ret;
}

@end
