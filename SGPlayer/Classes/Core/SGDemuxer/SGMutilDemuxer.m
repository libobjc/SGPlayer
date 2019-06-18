//
//  SGMutilDemuxer.m
//  SGPlayer
//
//  Created by Single on 2018/11/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGMutilDemuxer.h"
#import "SGError.h"

@interface SGMutilDemuxer ()

@property (nonatomic, strong, readonly) NSArray<id<SGDemuxable>> *demuxables;
@property (nonatomic, strong, readonly) NSMutableArray<id<SGDemuxable>> *finishedDemuxables;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSValue *> *timeStamps;

@end

@implementation SGMutilDemuxer

@synthesize tracks = _tracks;
@synthesize duration = _duration;
@synthesize metadata = _metadata;

- (instancetype)initWithDemuxables:(NSArray<id<SGDemuxable>> *)demuxables
{
    if (self = [super init]) {
        self->_demuxables = demuxables;
        self->_finishedDemuxables = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Setter & Getter

- (void)setDelegate:(id<SGDemuxableDelegate>)delegate
{
    for (id<SGDemuxable> obj in self->_demuxables) {
        obj.delegate = delegate;
    }
}

- (id<SGDemuxableDelegate>)delegate
{
    return self->_demuxables.firstObject.delegate;
}

- (void)setOptions:(SGDemuxerOptions *)options
{
    for (id<SGDemuxable> obj in self->_demuxables) {
        obj.options = options;
    }
}

- (SGDemuxerOptions *)options
{
    return self->_demuxables.firstObject.options;
}

#pragma mark - Control

- (NSError *)open
{
    for (id<SGDemuxable> obj in self->_demuxables) {
        NSError *error = [obj open];
        if (error) {
            return error;
        }
    }
    CMTime duration = kCMTimeZero;
    NSMutableArray<SGTrack *> *tracks = [NSMutableArray array];
    for (id<SGDemuxable> obj in self->_demuxables) {
        NSAssert(CMTIME_IS_VALID(obj.duration), @"Invalid Duration.");
        duration = CMTimeMaximum(duration, obj.duration);
        [tracks addObjectsFromArray:obj.tracks];
    }
    self->_duration = duration;
    self->_tracks = [tracks copy];
    NSMutableArray<NSNumber *> *indexes = [NSMutableArray array];
    for (SGTrack *obj in self->_tracks) {
        NSAssert(![indexes containsObject:@(obj.index)], @"Invalid Track Indexes");
        [indexes addObject:@(obj.index)];
    }
    self->_timeStamps = [NSMutableDictionary dictionary];
    return nil;
}

- (NSError *)close
{
    for (id<SGDemuxable> obj in self->_demuxables) {
        NSError *error = [obj close];
        if (error) {
            return error;
        }
    }
    return nil;
}

- (NSError *)seekable
{
    for (id<SGDemuxable> obj in self->_demuxables) {
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
        return SGECreateError(SGErrorCodeInvlidTime, SGOperationCodeFormatSeekFrame);
    }
    for (id<SGDemuxable> obj in self->_demuxables) {
        NSError *error = [obj seekToTime:time];
        if (error) {
            return error;
        }
    }
    [self->_timeStamps removeAllObjects];
    [self->_finishedDemuxables removeAllObjects];
    return nil;
}

- (NSError *)nextPacket:(SGPacket **)packet
{
    NSError *error = nil;
    while (YES) {
        id<SGDemuxable> demuxable = nil;
        CMTime minimumTime = kCMTimePositiveInfinity;
        for (id<SGDemuxable> obj in self->_demuxables) {
            if ([self->_finishedDemuxables containsObject:obj]) {
                continue;
            }
            NSString *key = [NSString stringWithFormat:@"%p", obj];
            NSValue *value = [self->_timeStamps objectForKey:key];
            if (!value) {
                demuxable = obj;
                break;
            }
            CMTime time = kCMTimePositiveInfinity;
            [value getValue:&time];
            if (CMTimeCompare(time, minimumTime) < 0) {
                minimumTime = time;
                demuxable = obj;
            }
        }
        if (!demuxable) {
            return SGECreateError(SGErrorCodeMutilDemuxerEndOfFile, SGOperationCodeMutilDemuxerNext);
        }
        error = [demuxable nextPacket:packet];
        if (error) {
            if (error.code == SGErrorImmediateExitRequested) {
                break;
            }
            [self->_finishedDemuxables addObject:demuxable];
            continue;
        }
        CMTime decodeTimeStamp = (*packet).decodeTimeStamp;
        NSString *key = [NSString stringWithFormat:@"%p", demuxable];
        NSValue *value = [NSValue value:&decodeTimeStamp withObjCType:@encode(CMTime)];
        [self->_timeStamps setObject:value forKey:key];
        break;
    }
    return error;
}

@end
