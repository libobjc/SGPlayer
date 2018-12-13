//
//  SGConcatDemuxer.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGConcatDemuxer.h"
#import "SGSegmentDemuxer.h"
#import "SGPacket+Internal.h"
#import "SGError.h"

@interface SGConcatDemuxer ()

@property (nonatomic, strong, readonly) SGMutableTrack *track;
@property (nonatomic, strong, readonly) SGSegmentDemuxer *currentUnit;
@property (nonatomic, strong, readonly) NSMutableArray<id<SGDemuxable>> *units;

@end

@implementation SGConcatDemuxer

@synthesize tracks = _tracks;
@synthesize duration = _duration;
@synthesize metadata = _metadata;

- (instancetype)initWithTrack:(SGMutableTrack *)track
{
    if (self = [super init]) {
        self->_track = [track copy];
        self->_tracks = @[track];
        self->_units = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

#pragma mark - Setter & Getter

- (void)setDelegate:(id<SGDemuxableDelegate>)delegate
{
    for (SGSegmentDemuxer *obj in self->_units) {
        obj.delegate = delegate;
    }
}

- (id<SGDemuxableDelegate>)delegate
{
    return self->_units.firstObject.delegate;
}

- (void)setOptions:(NSDictionary *)options
{
    for (SGSegmentDemuxer *obj in self->_units) {
        obj.options = options;
    }
}

- (NSDictionary *)options
{
    return self->_units.firstObject.options;
}

#pragma mark - Control

- (NSError *)open
{
    CMTime duration = kCMTimeZero;
    for (SGSegment *obj in self->_track.segments) {
        SGSegmentDemuxer *unit = [[SGSegmentDemuxer alloc] initWithSegment:obj];
        [self->_units addObject:unit];
        NSError *error = [unit open];
        if (error) {
            return error;
        }
        NSAssert(CMTIME_IS_VALID(unit.duration), @"Invaild Duration.");
        NSAssert(self->_track.type == unit.tracks.firstObject.type, @"Invaild mediaType.");
        unit.timeRange = CMTimeRangeMake(duration, unit.duration);
        duration = CMTimeRangeGetEnd(obj.timeRange);
    }
    self->_duration = duration;
    self->_currentUnit = self->_units.firstObject;
    [self->_currentUnit seekToTime:kCMTimeZero];
    return nil;
}

- (NSError *)close
{
    for (SGSegmentDemuxer *obj in self->_units) {
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
    time = CMTimeMaximum(time, kCMTimeZero);
    time = CMTimeMinimum(time, self->_duration);
    SGSegmentDemuxer *unit = nil;
    for (SGSegmentDemuxer *obj in self->_units) {
        if (CMTimeCompare(time, CMTimeRangeGetEnd(obj.timeRange)) <= 0) {
            unit = obj;
            break;
        }
    }
    self->_currentUnit = unit ? unit : self->_units.lastObject;
    return [self->_currentUnit seekToTime:CMTimeSubtract(time, self->_currentUnit.timeRange.start)];
}

- (NSError *)nextPacket:(SGPacket **)packet
{
    NSError *ret = nil;
    while (YES) {
        ret = [self->_currentUnit nextPacket:packet];
        if (ret) {
            if (ret.code == SGErrorImmediateExitRequested) {
                break;
            }
            if (self->_currentUnit == self->_units.lastObject) {
                break;
            }
            self->_currentUnit = [self->_units objectAtIndex:[self->_units indexOfObject:self->_currentUnit] + 1];
            [self->_currentUnit seekToTime:kCMTimeZero];
            continue;
        }
        (*packet).codecDescription.track = self->_tracks.firstObject;
        [(*packet) fill];
        break;
    }
    return ret;
}

@end
