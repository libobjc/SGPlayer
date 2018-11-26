//
//  SGConcatDemuxer.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGConcatDemuxer.h"
#import "SGConcatDemuxerUnit.h"
#import "SGPacket+Internal.h"
#import "SGError.h"

@interface SGConcatDemuxer ()

{
    CMTime _duration;
    NSDictionary *_metadata;
    NSArray<SGTrack *> *_tracks;
    NSArray<id<SGDemuxable>> *_units;
    SGConcatDemuxerUnit *_currentUnit;
}

@end

@implementation SGConcatDemuxer

- (instancetype)initWithTrack:(SGTrack *)track segments:(NSArray<SGSegment *> *)segments
{
    if (self = [super init]) {
        NSMutableArray *units = [NSMutableArray array];
        for (SGSegment *obj in segments) {
            [units addObject:[[SGConcatDemuxerUnit alloc] initWithSegment:obj]];
        }
        self->_units = [units copy];
        self->_tracks = @[track];
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

#pragma mark - Setter & Getter

- (void)setDelegate:(id <SGDemuxableDelegate>)delegate
{
    for (SGConcatDemuxerUnit *obj in self->_units) {
        obj.delegate = delegate;
    }
}

- (id <SGDemuxableDelegate>)delegate
{
    return self->_units.firstObject.delegate;
}

- (void)setOptions:(NSDictionary *)options
{
    for (SGConcatDemuxerUnit *obj in self->_units) {
        obj.options = options;
    }
}

- (NSDictionary *)options
{
    return self->_units.firstObject.options;
}

- (CMTime)duration
{
    return self->_duration;
}

- (NSDictionary *)metadata
{
    return [self->_metadata copy];
}

- (NSArray<SGTrack *> *)tracks
{
    return [self->_tracks copy];
}

#pragma mark - Control

- (NSError *)open
{
    NSError *ret = nil;
    CMTime duration = kCMTimeZero;
    for (SGConcatDemuxerUnit *obj in self->_units) {
        ret = [obj open];
        if (ret) {
            break;
        }
        NSAssert(self->_tracks.firstObject.type == obj.tracks.firstObject.type, @"Invaild mediaType.");
        obj.timeRange = CMTimeRangeMake(duration, obj.duration);
        duration = CMTimeRangeGetEnd(obj.timeRange);
    }
    self->_duration = duration;
    self->_currentUnit = self->_units.firstObject;
    [self->_currentUnit seekToTime:kCMTimeZero];
    return ret;
}

- (NSError *)close
{
    for (SGConcatDemuxerUnit *obj in self->_units) {
        [obj close];
    }
    return nil;
}

- (NSError *)seekable
{
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    SGConcatDemuxerUnit *unit = nil;
    for (SGConcatDemuxerUnit *obj in self->_units) {
        if (CMTimeRangeContainsTime(obj.timeRange, time) ||
            CMTimeCompare(CMTimeRangeGetEnd(obj.timeRange), time) == 0) {
            unit = obj;
            break;
        }
    }
    if (!unit) {
        return SGECreateError(SGErrorCodeConcatDemuxerNotFoundUnit,
                              SGOperationCodeURLDemuxerSeek);
    }
    self->_currentUnit = unit;
    return [self->_currentUnit seekToTime:CMTimeSubtract(time, self->_currentUnit.timeRange.start)];
}

- (NSError *)nextPacket:(SGPacket **)packet
{
    NSError *ret = nil;
    while (YES) {
        ret = [self->_currentUnit nextPacket:packet];
        if (!ret) {
            (*packet).codecDescription.track = self->_tracks.firstObject;
            [(*packet) fill];
            break;
        }
        if (self->_currentUnit == self->_units.lastObject) {
            break;
        }
        self->_currentUnit = [self->_units objectAtIndex:[self->_units indexOfObject:self->_currentUnit] + 1];
        [self->_currentUnit seekToTime:kCMTimeZero];
        continue;
    }
    return ret;
}

@end
