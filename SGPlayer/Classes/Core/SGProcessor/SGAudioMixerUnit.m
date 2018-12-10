//
//  SGAudioMixerUnit.m
//  SGPlayer
//
//  Created by Single on 2018/11/29.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioMixerUnit.h"

@interface SGAudioMixerUnit ()

{
    SGCapacity *_capacity;
    NSMutableArray<SGAudioFrame *> *_frames;
}

@end

@implementation SGAudioMixerUnit

- (instancetype)init
{
    if (self = [super init]) {
        [self flush];
    }
    return self;
}

- (void)dealloc
{
    for (SGAudioFrame *obj in self->_frames) {
        [obj unlock];
    }
}

#pragma mark - Control

- (BOOL)putFrame:(SGAudioFrame *)frame
{
    if (CMTIMERANGE_IS_VALID(self->_timeRange) && CMTimeCompare(frame.timeStamp, CMTimeRangeGetEnd(self->_timeRange)) < 0) {
        return NO;
    }
    [frame lock];
    [self->_frames addObject:frame];
    [self updateTimeRange];
    return YES;
}

- (NSArray<SGAudioFrame *> *)framesToEndTime:(CMTime)endTime
{
    NSMutableArray<SGAudioFrame *> *ret = [NSMutableArray array];
    NSMutableArray<SGAudioFrame *> *remove = [NSMutableArray array];
    for (SGAudioFrame *obj in self->_frames) {
        if (CMTimeCompare(obj.timeStamp, endTime) < 0) {
            [obj lock];
            [ret addObject:obj];
        }
        if (CMTimeCompare(CMTimeAdd(obj.timeStamp, obj.duration), endTime) <= 0) {
            [obj unlock];
            [remove addObject:obj];
        }
    }
    [self->_frames removeObjectsInArray:remove];
    [self updateTimeRange];
    return [ret copy];
}

- (SGCapacity *)capacity
{
    return [self->_capacity copy];
}

- (void)flush
{
    for (SGAudioFrame *obj in self->_frames) {
        [obj unlock];
    }
    self->_capacity = [[SGCapacity alloc] init];
    self->_frames = [NSMutableArray array];
    self->_timeRange = kCMTimeRangeInvalid;
}

#pragma mark - Internal

- (void)updateTimeRange
{
    self->_capacity.count = (int)self->_frames.count;
    if (self->_frames.count == 0) {
        self->_timeRange = kCMTimeRangeInvalid;
    } else {
        CMTime start = self->_frames.firstObject.timeStamp;
        CMTime end = CMTimeAdd(self->_frames.lastObject.timeStamp, self->_frames.lastObject.duration);
        CMTime duration = CMTimeSubtract(end, start);
        self->_timeRange = CMTimeRangeMake(start, duration);
    }
}

@end
