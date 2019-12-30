//
//  SGTrackDemuxer.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGTrackDemuxer.h"
#import "SGTrack+Internal.h"
#import "SGPacket+Internal.h"
#import "SGSegment+Internal.h"
#import "SGError.h"

@interface SGTrackDemuxer ()

@property (nonatomic, readonly) NSInteger currentIndex;
@property (nonatomic, strong, readonly) SGMutableTrack *track;
@property (nonatomic, strong, readonly) SGTimeLayout *currentLayout;
@property (nonatomic, strong, readonly) id<SGDemuxable> currentDemuxer;
@property (nonatomic, strong, readonly) NSMutableArray<SGTimeLayout *> *layouts;
@property (nonatomic, strong, readonly) NSMutableArray<id<SGDemuxable>> *demuxers;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, id<SGDemuxable>> *sharedDemuxers;

@end

@implementation SGTrackDemuxer

@synthesize tracks = _tracks;
@synthesize options = _options;
@synthesize delegate = _delegate;
@synthesize duration = _duration;
@synthesize metadata = _metadata;
@synthesize finishedTracks = _finishedTracks;

- (instancetype)initWithTrack:(SGMutableTrack *)track
{
    if (self = [super init]) {
        self->_track = [track copy];
        self->_tracks = @[self->_track];
        self->_layouts = [NSMutableArray array];
        self->_demuxers = [NSMutableArray array];
        self->_sharedDemuxers = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Setter & Getter

- (void)setDelegate:(id<SGDemuxableDelegate>)delegate
{
    self->_delegate = delegate;
    for (id<SGDemuxable> obj in self->_demuxers) {
        obj.delegate = delegate;
    }
}

- (void)setOptions:(SGDemuxerOptions *)options
{
    self->_options = [options copy];
    for (id<SGDemuxable> obj in self->_demuxers) {
        obj.options = options;
    }
}

#pragma mark - Control

- (id<SGDemuxable>)sharedDemuxer
{
    return nil;
}

- (NSError *)open
{
    CMTime basetime = kCMTimeZero;
    NSMutableArray<SGTrack *> *subTracks = [NSMutableArray array];
    for (SGSegment *obj in self->_track.segments) {
        SGTimeLayout *layout = [[SGTimeLayout alloc] initWithOffset:basetime];
        NSString *demuxerKey = [obj sharedDemuxerKey];
        id<SGDemuxable> sharedDemuxer = self->_sharedDemuxers[demuxerKey];
        id<SGDemuxable> demuxer = nil;
        if (!demuxerKey) {
            demuxer = [obj newDemuxer];
        } else if (sharedDemuxer) {
            demuxer = [obj newDemuxerWithSharedDemuxer:sharedDemuxer];
        } else {
            demuxer = [obj newDemuxer];
            id<SGDemuxable> reuseDemuxer = [demuxer sharedDemuxer];
            if (reuseDemuxer) {
                self->_sharedDemuxers[demuxerKey] = reuseDemuxer;
            }
        }
        demuxer.options = self->_options;
        demuxer.delegate = self->_delegate;
        [self->_layouts addObject:layout];
        [self->_demuxers addObject:demuxer];
        NSError *error = [demuxer open];
        if (error) {
            return error;
        }
        NSAssert(CMTIME_IS_VALID(demuxer.duration), @"Invaild Duration.");
        NSAssert(!demuxer.tracks.firstObject || demuxer.tracks.firstObject.type == self->_track.type, @"Invaild mediaType.");
        basetime = CMTimeAdd(basetime, demuxer.duration);
        if (demuxer.tracks.firstObject) {
            [subTracks addObject:demuxer.tracks.firstObject];
        }
    }
    self->_duration = basetime;
    self->_track.subTracks = subTracks;
    self->_currentIndex = 0;
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
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid];
}

- (NSError *)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter
{
    if (!CMTIME_IS_NUMERIC(time)) {
        return SGCreateError(SGErrorCodeInvlidTime, SGActionCodeFormatSeekFrame);
    }
    time = CMTimeMaximum(time, kCMTimeZero);
    time = CMTimeMinimum(time, self->_duration);
    NSInteger currentIndex = self->_demuxers.count - 1;
    SGTimeLayout *currentLayout = self->_layouts.lastObject;
    id<SGDemuxable> currentDemuxer = self->_demuxers.lastObject;
    for (NSUInteger i = 0; i < self->_demuxers.count; i++) {
        SGTimeLayout *layout = [self->_layouts objectAtIndex:i];
        id<SGDemuxable> demuxer = [self->_demuxers objectAtIndex:i];
        if (CMTimeCompare(time, CMTimeAdd(layout.offset, demuxer.duration)) <= 0) {
            currentIndex = i;
            currentLayout = layout;
            currentDemuxer = demuxer;
            break;
        }
    }
    time = CMTimeSubtract(time, currentLayout.offset);
    self->_finishedTracks = nil;
    self->_currentIndex = currentIndex;
    self->_currentLayout = currentLayout;
    self->_currentDemuxer = currentDemuxer;
    return [self->_currentDemuxer seekToTime:time toleranceBefor:toleranceBefor toleranceAfter:toleranceAfter];
}

- (NSError *)nextPacket:(SGPacket **)packet
{
    NSError *error = nil;
    while (YES) {
        if (!self->_currentDemuxer) {
            error = SGCreateError(SGErrorCodeDemuxerEndOfFile, SGActionCodeFormatReadFrame);
            break;
        }
        error = [self->_currentDemuxer nextPacket:packet];
        if (error) {
            if (error.code == SGErrorImmediateExitRequested) {
                break;
            }
            NSInteger nextIndex = self->_currentIndex + 1;
            if (nextIndex < self->_demuxers.count) {
                self->_currentIndex = nextIndex;
                self->_currentLayout = [self->_layouts objectAtIndex:nextIndex];
                self->_currentDemuxer = [self->_demuxers objectAtIndex:nextIndex];
                [self->_currentDemuxer seekToTime:kCMTimeZero];
            } else {
                self->_currentIndex = 0;
                self->_currentLayout = nil;
                self->_currentDemuxer = nil;
            }
            continue;
        }
        [(*packet).codecDescriptor setTrack:self->_track];
        [(*packet).codecDescriptor appendTimeLayout:self->_currentLayout];
        [(*packet) fill];
        break;
    }
    if (error.code == SGErrorCodeDemuxerEndOfFile) {
        self->_finishedTracks = self->_tracks.copy;
    }
    return error;
}

@end
