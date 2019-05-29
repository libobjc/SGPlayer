//
//  SGTrackDemuxer.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGTrackDemuxer.h"
#import "SGSegmentDemuxer.h"
#import "SGPacket+Internal.h"
#import "SGError.h"

@interface SGTrackDemuxer ()

@property (nonatomic, strong, readonly) SGMutableTrack *track;
@property (nonatomic, strong, readonly) SGSegmentDemuxer *currentSegment;
@property (nonatomic, strong, readonly) NSMutableArray<id<SGDemuxable>> *segments;

@end

@implementation SGTrackDemuxer

@synthesize tracks = _tracks;
@synthesize duration = _duration;
@synthesize metadata = _metadata;

- (instancetype)initWithTrack:(SGMutableTrack *)track
{
    if (self = [super init]) {
        self->_track = [track copy];
        self->_tracks = @[self->_track];
        self->_segments = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Setter & Getter

- (void)setDelegate:(id<SGDemuxableDelegate>)delegate
{
    for (SGSegmentDemuxer *obj in self->_segments) {
        obj.delegate = delegate;
    }
}

- (id<SGDemuxableDelegate>)delegate
{
    return self->_segments.firstObject.delegate;
}

- (void)setOptions:(NSDictionary *)options
{
    for (SGSegmentDemuxer *obj in self->_segments) {
        obj.options = options;
    }
}

- (NSDictionary *)options
{
    return self->_segments.firstObject.options;
}

#pragma mark - Control

- (NSError *)open
{
    CMTime basetime = kCMTimeZero;
    for (SGSegment *obj in self->_track.segments) {
        SGSegmentDemuxer *segment = [[SGSegmentDemuxer alloc] initWithSegment:obj basetime:basetime];
        [self->_segments addObject:segment];
        NSError *error = [segment open];
        if (error) {
            return error;
        }
        NSAssert(CMTIME_IS_VALID(segment.duration), @"Invaild Duration.");
        NSAssert(!segment.tracks.firstObject || segment.tracks.firstObject.type == self->_track.type, @"Invaild mediaType.");
        basetime = CMTimeAdd(basetime, segment.duration);
    }
    self->_duration = basetime;
    self->_currentSegment = self->_segments.firstObject;
    [self->_currentSegment seekToTime:kCMTimeZero];
    return nil;
}

- (NSError *)close
{
    for (SGSegmentDemuxer *obj in self->_segments) {
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
    for (SGSegmentDemuxer *obj in self->_segments) {
        if (CMTimeCompare(time, CMTimeAdd(obj.basetime, obj.duration)) <= 0) {
            unit = obj;
            break;
        }
    }
    self->_currentSegment = unit ? unit : self->_segments.lastObject;
    return [self->_currentSegment seekToTime:CMTimeSubtract(time, self->_currentSegment.basetime)];
}

- (NSError *)nextPacket:(SGPacket **)packet
{
    NSError *error = nil;
    while (YES) {
        error = [self->_currentSegment nextPacket:packet];
        if (error) {
            if (error.code == SGErrorImmediateExitRequested) {
                break;
            }
            if (self->_currentSegment == self->_segments.lastObject) {
                break;
            }
            self->_currentSegment = [self->_segments objectAtIndex:[self->_segments indexOfObject:self->_currentSegment] + 1];
            [self->_currentSegment seekToTime:kCMTimeZero];
            continue;
        }
        (*packet).codecDescription.track = self->_track;
        [(*packet) fill];
        break;
    }
    return error;
}

@end
