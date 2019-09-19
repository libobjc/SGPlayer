//
//  SGTrackDemuxer.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGTrackDemuxer.h"
#import "SGPacket+Internal.h"
#import "SGSegment+Internal.h"
#import "SGError.h"

@interface SGTrackDemuxer ()

@property (nonatomic, strong, readonly) SGMutableTrack *track;
@property (nonatomic, strong, readonly) SGTimeLayout *currentLayout;
@property (nonatomic, strong, readonly) id<SGDemuxable> currentDemuxer;
@property (nonatomic, strong, readonly) NSMutableArray<SGTimeLayout *> *layouts;
@property (nonatomic, strong, readonly) NSMutableArray<id<SGDemuxable>> *demuxers;


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
        self->_layouts = [NSMutableArray array];
        self->_demuxers = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Setter & Getter

- (void)setDelegate:(id<SGDemuxableDelegate>)delegate
{
    for (id<SGDemuxable> obj in self->_demuxers) {
        obj.delegate = delegate;
    }
}

- (id<SGDemuxableDelegate>)delegate
{
    return self->_demuxers.firstObject.delegate;
}

- (void)setOptions:(SGDemuxerOptions *)options
{
    for (id<SGDemuxable> obj in self->_demuxers) {
        obj.options = options;
    }
}

- (SGDemuxerOptions *)options
{
    return self->_demuxers.firstObject.options;
}

#pragma mark - Control

- (NSError *)open
{
    CMTime basetime = kCMTimeZero;
    for (SGSegment *obj in self->_track.segments) {
        SGTimeLayout *layout = [[SGTimeLayout alloc] initWithOffset:basetime];
        id<SGDemuxable> demuxer = [obj newDemuxable];
        [self->_layouts addObject:layout];
        [self->_demuxers addObject:demuxer];
        NSError *error = [demuxer open];
        if (error) {
            return error;
        }
        NSAssert(CMTIME_IS_VALID(demuxer.duration), @"Invaild Duration.");
        NSAssert(!demuxer.tracks.firstObject || demuxer.tracks.firstObject.type == self->_track.type, @"Invaild mediaType.");
        
        basetime = CMTimeAdd(basetime, demuxer.duration);
    }
    self->_duration = basetime;
    self->_currentLayout = self->_layouts.firstObject;
    self->_currentDemuxer = self->_demuxers.firstObject;
    [self->_currentDemuxer seekToTime:kCMTimeZero];
    return nil;
}

- (NSError *)close
{
    for (id<SGDemuxable> obj in self->_demuxers) {
        [obj close];
    }
    return nil;
}

- (NSError *)seekable
{
    for (id<SGDemuxable> obj in self->_demuxers) {
        NSError *error = [obj seekable];
        if (error) {
            return error;
        }
    }
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    if (!CMTIME_IS_NUMERIC(time)) {
        return SGCreateError(SGErrorCodeInvlidTime, SGActionCodeFormatSeekFrame);
    }
    time = CMTimeMaximum(time, kCMTimeZero);
    time = CMTimeMinimum(time, self->_duration);
    SGTimeLayout *currentLayout = self->_layouts.lastObject;
    id<SGDemuxable> currentDemuxer = self->_demuxers.lastObject;
    for (NSUInteger i = 0; i < self->_demuxers.count; i++) {
        SGTimeLayout *layout = [self->_layouts objectAtIndex:i];
        id<SGDemuxable> demuxer = [self->_demuxers objectAtIndex:i];
        if (CMTimeCompare(time, CMTimeAdd(layout.offset, demuxer.duration)) <= 0) {
            currentLayout = layout;
            currentDemuxer = demuxer;
            break;
        }
    }
    time = CMTimeSubtract(time, currentLayout.offset);
    self->_currentLayout = currentLayout;
    self->_currentDemuxer = currentDemuxer;
    return [self->_currentDemuxer seekToTime:time];
}

- (NSError *)nextPacket:(SGPacket **)packet
{
    NSError *error = nil;
    while (YES) {
        error = [self->_currentDemuxer nextPacket:packet];
        if (error) {
            if (error.code == SGErrorImmediateExitRequested) {
                break;
            }
            if (self->_currentDemuxer == self->_demuxers.lastObject) {
                break;
            }
            NSUInteger index = [self->_demuxers indexOfObject:self->_currentDemuxer];
            self->_currentLayout = [self->_layouts objectAtIndex:index + 1];
            self->_currentDemuxer = [self->_demuxers objectAtIndex:index + 1];
            [self->_currentDemuxer seekToTime:kCMTimeZero];
            continue;
        }
        [(*packet).codecDescriptor setTrack:self->_track];
        [(*packet).codecDescriptor appendTimeLayout:self->_currentLayout];
        [(*packet) fill];
        break;
    }
    return error;
}

@end
