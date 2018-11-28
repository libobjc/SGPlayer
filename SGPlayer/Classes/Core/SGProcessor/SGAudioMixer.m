//
//  SGAudioMixer.m
//  SGPlayer
//
//  Created by Single on 2018/11/28.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioMixer.h"
#import "SGObjectQueue.h"
#import "SGPointerMap.h"
#import "SGLock.h"

@interface SGAudioMixer ()

{
    CMTime _startTime;
    CMTime _minimumTimeStamp;
    CMTime _maximumTimeStamp;
    SGPointerMap *_timeStamps;
    NSArray<SGTrack *> *_tracks;
    NSArray<NSNumber *> *_weights;
    NSMutableDictionary<NSNumber *, NSMutableArray<SGAudioFrame *> *> *_frameLists;
}

@end

@implementation SGAudioMixer

- (instancetype)init
{
    if (self = [super init]) {
        self->_startTime = kCMTimeNegativeInfinity;
        self->_timeStamps = [[SGPointerMap alloc] init];
        self->_frameLists = [NSMutableDictionary dictionary];
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

- (SGAudioFrame *)mix:(SGAudioFrame *)frame
{
    if (self.tracks.count <= 1) {
        return frame;
    }
    if (CMTimeCompare(frame.timeStamp, self->_startTime) < 0) {
        [frame unlock];
        return nil;
    }
    NSMutableArray<SGAudioFrame *> *frames = [self->_frameLists objectForKey:@(frame.track.index)];
    if (!frames) {
        frames = [NSMutableArray array];
        [self->_frameLists setObject:frames forKey:@(frame.track.index)];
    }
    if (frames.lastObject && CMTimeCompare(frame.timeStamp, frames.lastObject.timeStamp) <= 0) {
        [frame unlock];
        return nil;
    }
    [frames addObject:frame];
    
    for (SGTrack *obj in self->_tracks) {
        NSUInteger count = [self->_frameLists objectForKey:@(obj.index)].count;
        NSLog(@"index : %d, count : %ld", frame.track.type, count);
    }
    return nil;
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
