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

@property (nonatomic, strong) SGConcatDemuxerUnit * currentUnit;
@property (nonatomic, strong) NSArray <SGConcatDemuxerUnit *> * units;
@property (nonatomic) SGMediaType type;
@property (nonatomic) CMTime duration;
@property (nonatomic) uint32_t index;

@end

@implementation SGConcatDemuxer

- (instancetype)initWithType:(SGMediaType)type index:(int32_t)index segments:(NSArray <SGSegment *> *)segments
{
    if (self = [super init]) {
        NSMutableArray * units = [NSMutableArray array];
        for (SGSegment * obj in segments) {
            [units addObject:[[SGConcatDemuxerUnit alloc] initWithSegment:obj]];
        }
        self.units = [units copy];
        self.type = type;
        self.index = index;
    }
    return self;
}

- (void)setDelegate:(id <SGDemuxableDelegate>)delegate
{
    for (SGConcatDemuxerUnit * obj in self.units) {
        obj.delegate = delegate;
    }
}

- (id <SGDemuxableDelegate>)delegate
{
    return self.units.firstObject.delegate;
}

- (void)setOptions:(NSDictionary *)options
{
    for (SGConcatDemuxerUnit * obj in self.units) {
        obj.options = options;
    }
}

- (NSDictionary *)options
{
    return self.units.firstObject.options;
}

- (NSError *)seekable
{
    return nil;
}

- (NSDictionary *)metadata
{
    return nil;
}

- (NSArray *)tracks
{
    return self.units.firstObject.tracks;
}

- (NSArray *)audioTracks
{
    return self.units.firstObject.audioTracks;
}

- (NSArray *)videoTracks
{
    return self.units.firstObject.videoTracks;
}

- (NSArray *)otherTracks
{
    return self.units.firstObject.otherTracks;
}

- (NSError *)open
{
    NSError * ret = nil;
    CMTime duration = kCMTimeZero;
    for (SGConcatDemuxerUnit * obj in self.units) {
        ret = [obj open];
        if (ret) {
            break;
        }
        NSAssert(self.type == obj.tracks.firstObject.type, @"Invaild mediaType.");
        obj.timeRange = CMTimeRangeMake(duration, obj.duration);
        duration = CMTimeRangeGetEnd(obj.timeRange);
    }
    self.duration = duration;
    self.currentUnit = self.units.firstObject;
    [self.currentUnit seekToTime:kCMTimeZero];
    return ret;
}

- (NSError *)close
{
    for (SGConcatDemuxerUnit * obj in self.units) {
        [obj close];
    }
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    SGConcatDemuxerUnit * unit = nil;
    for (SGConcatDemuxerUnit * obj in self.units) {
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
    self.currentUnit = unit;
    return [self.currentUnit seekToTime:CMTimeSubtract(time, self.currentUnit.timeRange.start)];
}

- (NSError *)nextPacket:(SGPacket *)packet
{
    NSError * ret = nil;
    while (YES) {
        ret = [self.currentUnit nextPacket:packet];
        if (!ret) {
            [packet setIndex:self.index];
            break;
        }
        if (self.currentUnit == self.units.lastObject) {
            break;
        }
        self.currentUnit = [self.units objectAtIndex:[self.units indexOfObject:self.currentUnit] + 1];
        [self.currentUnit seekToTime:kCMTimeZero];
        continue;
    }
    return ret;
}

@end
