//
//  SGAudioProcessor.m
//  SGPlayer
//
//  Created by Single on 2018/11/28.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioProcessor.h"
#import "SGAudioFormatter.h"
#import "SGFrame+Internal.h"
#import "SGObjectQueue.h"
#import "SGPointerMap.h"
#import "avformat.h"
#import "SGLock.h"

@interface SGAudioProcessor ()

{
    CMTime _startTime;
    CMTime _minimumTimeStamp;
    CMTime _maximumTimeStamp;
    SGPointerMap *_timeStamps;
    NSArray<SGTrack *> *_tracks;
    NSArray<NSNumber *> *_weights;
    NSMutableDictionary<NSNumber *, SGAudioFormatter *> *_filters;
    NSMutableDictionary<NSNumber *, NSMutableArray<SGAudioFrame *> *> *_frameLists;
}

@end

@implementation SGAudioProcessor

- (instancetype)init
{
    if (self = [super init]) {
        self->_startTime = kCMTimeNegativeInfinity;
        self->_timeStamps = [[SGPointerMap alloc] init];
        self->_filters = [NSMutableDictionary dictionary];
        self->_frameLists = [NSMutableDictionary dictionary];
        self->_audioDescription = [[SGAudioDescription alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self flush];
}

#pragma mark - Setter & Getter

- (NSArray<SGTrack *> *)tracks
{
    return self->_tracks;;
}

- (NSArray<NSNumber *> *)weights
{
    return self->_weights;
}

- (BOOL)setTracks:(NSArray<SGTrack *> *)tracks weights:(NSArray<NSNumber *> *)weights
{
    if (tracks.count > 0 && ![tracks isEqualToArray:self->_tracks]) {
        self->_tracks = tracks;
        self->_weights = nil;
    }
    if (weights.count > 0) {
        self->_weights = weights;
    }
    if (self->_tracks.count != self->_weights.count) {
        NSMutableArray *w = [NSMutableArray array];
        for (int i = 0; i < tracks.count; i++) {
            [w addObject:@(100)];
        }
        self->_weights = [w copy];
    }
    return YES;
}

- (BOOL)isAvailable
{
    return self->_tracks.count > 0;
}

- (SGCapacity *)capacity
{
    return [[SGCapacity alloc] init];
}

#pragma mark - Control

- (SGAudioFrame *)putFrame:(SGAudioFrame *)frame
{
    if (![self->_tracks containsObject:frame.track]) {
        [frame unlock];
        return nil;
    }
    SGAudioFormatter *formatter = [self->_filters objectForKey:@(frame.track.index)];
    if (!formatter) {
        formatter = [[SGAudioFormatter alloc] init];
        formatter.audioDescription = self->_audioDescription;
        [self->_filters setObject:formatter forKey:@(frame.track.index)];
    }
    SGAudioFrame *formatted = nil;
    [formatter format:frame formatted:&formatted];
    [frame unlock];
    if (!formatted) {
        return nil;
    }
    // Don't have to mix.
    if (self->_tracks.count <= 1) {
        return formatted;
    }
    // Have to mix.
    if (CMTimeCompare(frame.timeStamp, self->_startTime) < 0) {
        [formatted unlock];
        return nil;
    }
    NSMutableArray<SGAudioFrame *> *queue = [self->_frameLists objectForKey:@(formatted.track.index)];
    if (!queue) {
        queue = [NSMutableArray array];
        [self->_frameLists setObject:queue forKey:@(formatted.track.index)];
    }
    if (queue.lastObject && CMTimeCompare(formatted.timeStamp, queue.lastObject.timeStamp) <= 0) {
        [formatted unlock];
        return nil;
    }
    [queue addObject:formatted];
    return [self mixIfNeeded];
}

- (SGAudioFrame *)mixIfNeeded
{
    CMTime start = kCMTimePositiveInfinity;
    CMTime end = kCMTimePositiveInfinity;
    for (SGTrack *track in self->_tracks) {
        NSMutableArray<SGAudioFrame *> *frames = [self->_frameLists objectForKey:@(track.index)];
        if (frames.count < 3) {
            return nil;
        }
        CMTime currentStart = frames.firstObject.timeStamp;
        CMTime currentEnd = CMTimeAdd(frames.lastObject.timeStamp, frames.lastObject.duration);
        if (CMTimeCompare(currentStart, start) < 0) {
            start = frames.firstObject.timeStamp;
        }
        if (CMTimeCompare(currentEnd, end) < 0) {
            end = currentEnd;
        }
    }
    CMTime duration = CMTimeSubtract(end, start);
    
    int numberOfChannels = 2;
    int numberOfSamples = CMTimeGetSeconds(duration) * 44100;
    int linesize = av_get_bytes_per_sample(AV_SAMPLE_FMT_FLTP) * numberOfSamples;
    
    SGAudioFrame *result = [[SGObjectPool sharedPool] objectWithClass:[SGAudioFrame class]];
    result.core->format = AV_SAMPLE_FMT_FLTP;
    result.core->channels = 2;
    result.core->channel_layout = av_get_default_channel_layout(2);
    result.core->nb_samples = numberOfSamples;
    
    for (int i = 0; i < numberOfChannels; i++) {
        int index = 0;
        int offset = 0;
        SGAudioFrame *currentFrame = nil;
        SGAudioFrame *currentFrame2 = nil;
        float *data = av_mallocz(linesize);
        for (int j = 0; j < numberOfSamples; j++) {
            if (!currentFrame) {
                currentFrame = [[self->_frameLists objectForKey:@(0)] objectAtIndex:index];
                currentFrame2 = [[self->_frameLists objectForKey:@(1)] objectAtIndex:index];
                index += 1;
                offset = 0;
            }
            float *src = (float *)currentFrame.data[i];
            float *src2 = (float *)currentFrame2.data[i];
            data[j] = src[offset] * 0.5 + src2[offset] * 0.5;
            offset += 1;
            if (offset >= currentFrame.numberOfSamples) {
                currentFrame = nil;
                currentFrame2 = nil;
            }
        }
        AVBufferRef *buffer = av_buffer_create((uint8_t *)data, linesize, av_buffer_default_free, NULL, 0);
        result.core->buf[i] = buffer;
        result.core->data[i] = buffer->data;
        result.core->linesize[i] = buffer->size;
    }
    
    result.core->key_frame              = 1;
    result.core->pts                    = start.value;
    result.core->sample_rate            = 44100;
    result.core->pkt_dts                = start.value;
    result.core->pkt_size               = 0;
    result.core->pkt_duration           = duration.value;
    result.core->best_effort_timestamp  = start.value;
    
    SGCodecDescription *cd = [[SGCodecDescription alloc] init];
    cd.timebase = av_make_q(1, start.timescale);
    result.codecDescription = cd;
    [result fill];
    
    for (NSMutableArray<SGAudioFrame *> *obj in self->_frameLists.allValues) {
        for (SGAudioFrame *frame in obj) {
            [frame unlock];
        }
        [obj removeAllObjects];
    }
    
    return result;
}

- (void)close
{
    [self flush];
}

- (void)finish
{
    
}

- (void)flush
{
    for (NSMutableArray<SGAudioFrame *> *obj in self->_frameLists.allValues) {
        for (SGAudioFrame *frame in obj) {
            [frame unlock];
        }
        [obj removeAllObjects];
    }
    [self->_frameLists removeAllObjects];
}

@end
