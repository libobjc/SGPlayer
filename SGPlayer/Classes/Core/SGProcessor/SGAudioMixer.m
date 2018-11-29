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
    NSAssert(self->_audioDescription.format == frame.format, @"Invalid Format.");
    NSAssert(self->_audioDescription.format == AV_SAMPLE_FMT_FLTP, @"Invalid Format.");
    SGAudioMixerUnit *unit = [self->_units objectForKey:@(frame.track.index)];
    BOOL ret = [unit putFrame:frame];
    [frame unlock];
    if (ret) {
        return [self mixIfNeeded];
    }
    return nil;
}

- (SGAudioFrame *)finish
{
    if (self->_tracks.count <= 1) {
        return nil;
    }
    return nil;
}

- (SGCapacity *)capacity
{
    return [[SGCapacity alloc] init];
}

- (void)flush
{
    for (SGAudioMixerUnit *obj in self->_units.allValues) {
        [obj flush];
    }
    self->_startTime = kCMTimeNegativeInfinity;
}

- (SGAudioFrame *)mixIfNeeded
{
    CMTime start = kCMTimePositiveInfinity;
    CMTime end = kCMTimePositiveInfinity;
    CMTime duration = kCMTimeZero;
    CMTime maximumDuration = kCMTimeZero;
    
    for (SGAudioMixerUnit *obj in self->_units.allValues) {
        if (CMTIMERANGE_IS_INVALID(obj.timeRange)) {
            continue;
        }
        start = CMTimeMinimum(start, obj.timeRange.start);
        end = CMTimeMinimum(end, CMTimeRangeGetEnd(obj.timeRange));
        duration = CMTimeSubtract(end, start);
        maximumDuration = CMTimeMaximum(maximumDuration, obj.timeRange.duration);
    }
    if (CMTimeCompare(maximumDuration, CMTimeMake(4, 10)) < 0) {
        return nil;
    }
    self->_startTime = end;
    
    int sampleRate = self->_audioDescription.sampleRate;
    int numberOfSamples = CMTimeGetSeconds(duration) * sampleRate;
    int numberOfChannels = self->_audioDescription.numberOfChannels;
    int linesize = av_get_bytes_per_sample(AV_SAMPLE_FMT_FLTP) * numberOfSamples;

    SGAudioFrame *ret = [[SGObjectPool sharedPool] objectWithClass:[SGAudioFrame class]];

    ret.core->format = self->_audioDescription.format;
    ret.core->sample_rate = sampleRate;
    ret.core->channels = numberOfChannels;
    ret.core->channel_layout = self->_audioDescription.channelLayout;
    ret.core->nb_samples = numberOfSamples;
    ret.core->pts = av_rescale(sampleRate, start.value, start.timescale);
    ret.core->pkt_dts = av_rescale(sampleRate, start.value, start.timescale);
    ret.core->pkt_size = 0;
    ret.core->pkt_duration = av_rescale(sampleRate, duration.value, duration.timescale);
    ret.core->best_effort_timestamp = av_rescale(sampleRate, start.value, start.timescale);

    for (int i = 0; i < numberOfChannels; i++) {
        float *data = av_mallocz(linesize);
        AVBufferRef *buffer = av_buffer_create((uint8_t *)data, linesize, av_buffer_default_free, NULL, 0);
        ret.core->buf[i] = buffer;
        ret.core->data[i] = buffer->data;
        ret.core->linesize[i] = buffer->size;
    }
    
    NSMutableDictionary *list = [NSMutableDictionary dictionary];
    for (SGTrack *obj in self->_tracks) {
        NSArray *frames = [self->_units[@(obj.index)] framesToEndTime:end];
        if (frames.count > 0) {
            [list setObject:frames forKey:@(obj.index)];
        }
    }
    
    for (int i = 0; i < numberOfSamples; i++) {
        for (int j = 0; j < self->_tracks.count; j++) {
            for (SGAudioFrame *obj in list[@(self->_tracks[j].index)]) {
                int c = CMTimeGetSeconds(CMTimeSubtract(obj.timeStamp, start)) * sampleRate;
                if (i < c) {
                    break;
                }
                if (i >= c + obj.numberOfSamples) {
                    continue;
                }
                for (int k = 0; k < numberOfChannels; k++) {
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
    cd.timebase = av_make_q(1, self->_audioDescription.sampleRate);
    ret.codecDescription = cd;
    [ret fill];
    
    return ret;
}

@end
