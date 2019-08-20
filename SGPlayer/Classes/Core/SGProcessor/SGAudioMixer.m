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
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, SGAudioMixerUnit *> *units;

@end

@implementation SGAudioMixer

- (instancetype)initWithTracks:(NSArray<SGTrack *> *)tracks weights:(NSArray<NSNumber *> *)weights descriptor:(SGAudioDescriptor *)descriptor
{
    if (self = [super init]) {
        self->_tracks = [tracks copy];
        self->_weights = [weights copy];
        self->_descriptor = [descriptor copy];
        self->_startTime = kCMTimeNegativeInfinity;
        self->_units = [NSMutableDictionary dictionary];
        for (SGTrack *obj in self->_tracks) {
            [self->_units setObject:[[SGAudioMixerUnit alloc] init] forKey:@(obj.index)];
        }
    }
    return self;
}

#pragma mark - Control

- (SGAudioFrame *)putFrame:(SGAudioFrame *)frame
{
    if (self->_tracks.count <= 1) {
        return frame;
    }
    if (CMTimeCompare(CMTimeAdd(frame.timeStamp, frame.duration), self->_startTime) <= 0) {
        [frame unlock];
        return nil;
    }
    NSAssert([self->_descriptor isEqualToDescriptor:frame.descriptor], @"Invalid Format.");
    NSAssert(self->_descriptor.format == AV_SAMPLE_FMT_FLTP, @"Invalid Format.");
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

- (SGCapacity)capacity
{
    __block SGCapacity capacity = SGCapacityCreate();
    [self->_units enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, SGAudioMixerUnit *obj, BOOL *stop) {
        capacity = SGCapacityMaximum(capacity, obj.capacity);
    }];
    return capacity;
}

- (void)flush
{
    [self->_units enumerateKeysAndObjectsUsingBlock:^(id key, SGAudioMixerUnit *obj, BOOL *stop) {
        [obj flush];
    }];
    self->_startTime = kCMTimeNegativeInfinity;
}

#pragma mark - Mix

- (SGAudioFrame *)mixForPutFrame
{
    __block CMTime start = kCMTimePositiveInfinity;
    __block CMTime end = kCMTimePositiveInfinity;
    __block CMTime maximumDuration = kCMTimeZero;
    [self->_units enumerateKeysAndObjectsUsingBlock:^(id key, SGAudioMixerUnit *obj, BOOL *stop) {
        if (CMTIMERANGE_IS_INVALID(obj.timeRange)) {
            return;
        }
        start = CMTimeMinimum(start, obj.timeRange.start);
        start = CMTimeMaximum(start, self->_startTime);
        end = CMTimeMinimum(end, CMTimeRangeGetEnd(obj.timeRange));
        maximumDuration = CMTimeMaximum(maximumDuration, obj.timeRange.duration);
    }];
    if (CMTimeCompare(maximumDuration, CMTimeMake(8, 100)) < 0) {
        return nil;
    }
    return [self mixWithRange:CMTimeRangeFromTimeToTime(start, end)];
}

- (SGAudioFrame *)mixForFinish
{
    __block CMTime start = kCMTimePositiveInfinity;
    __block CMTime end = kCMTimeNegativeInfinity;
    [self->_units enumerateKeysAndObjectsUsingBlock:^(id key, SGAudioMixerUnit *obj, BOOL *stop) {
        if (CMTIMERANGE_IS_INVALID(obj.timeRange)) {
            return;
        }
        start = CMTimeMinimum(start, obj.timeRange.start);
        start = CMTimeMaximum(start, self->_startTime);
        end = CMTimeMaximum(end, CMTimeRangeGetEnd(obj.timeRange));
    }];
    if (CMTimeCompare(CMTimeSubtract(end, start), kCMTimeZero) <= 0) {
        return nil;
    }
    SGAudioFrame *frame = [self mixWithRange:CMTimeRangeFromTimeToTime(start, end)];
    [self->_units enumerateKeysAndObjectsUsingBlock:^(id key, SGAudioMixerUnit *obj, BOOL *stop) {
        [obj flush];
    }];
    return frame;
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
        Float64 sum = 0;
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
    SGAudioDescriptor *descriptor = self->_descriptor;
    int numberOfSamples = (int)CMTimeConvertScale(duration, descriptor.sampleRate, kCMTimeRoundingMethod_RoundTowardZero).value;
    SGAudioFrame *ret = [SGAudioFrame audioFrameWithDescriptor:descriptor numberOfSamples:numberOfSamples];
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
            int s = (int)CMTimeConvertScale(CMTimeSubtract(obj.timeStamp, start), descriptor.sampleRate, kCMTimeRoundingMethod_RoundTowardZero).value;
            int e = s + obj.numberOfSamples;
            int ss = MAX(0, s);
            int ee = MIN(numberOfSamples, e);
            if (ss - lastEE != 0) {
                NSRange range = NSMakeRange(MIN(ss, lastEE), ABS(ss - lastEE));
                [discontinuous addObject:[NSValue valueWithRange:range]];
            }
            lastEE = ee;
            for (int i = ss; i < ee; i++) {
                for (int c = 0; c < descriptor.numberOfPlanes; c++) {
                    ((float *)ret.core->data[c])[i] += (((float *)obj.data[c])[i - s] * weights[t].floatValue);
                }
            }
        }
    }
    for (NSValue *obj in discontinuous) {
        NSRange range = obj.rangeValue;
        for (int c = 0; c < descriptor.numberOfPlanes; c++) {
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
    [list enumerateKeysAndObjectsUsingBlock:^(id key, NSArray *objs, BOOL *stop) {
        for (SGAudioFrame *obj in objs) {
            [obj unlock];
        }
    }];
    [ret setCodecDescriptor:[[SGCodecDescriptor alloc] init]];
    [ret fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
    return ret;
}

@end
