//
//  SGMutilDemuxer.m
//  SGPlayer
//
//  Created by Single on 2018/11/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGMutilDemuxer.h"
#import "SGPointerMap.h"
#import "SGError.h"

@interface SGMutilDemuxer ()

{
    CMTime _duration;
    NSDictionary *_metadata;
    SGPointerMap *_timeStamps;
    NSArray<SGTrack *> *_tracks;
    NSArray<id<SGDemuxable>> *_demuxables;
    NSMutableArray<id<SGDemuxable>> *_finishedDemuxables;
}

@end

@implementation SGMutilDemuxer

- (instancetype)initWithDemuxables:(NSArray<id<SGDemuxable>> *)demuxables
{
    if (self = [super init]) {
        self->_demuxables = demuxables;
        self->_finishedDemuxables = [NSMutableArray array];
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
    for (id<SGDemuxable> obj in self->_demuxables) {
        obj.delegate = delegate;
    }
}

- (id<SGDemuxableDelegate>)delegate
{
    return self->_demuxables.firstObject.delegate;
}

- (void)setOptions:(NSDictionary *)options
{
    for (id<SGDemuxable> obj in self->_demuxables) {
        obj.options = options;
    }
}

- (NSDictionary *)options
{
    return self->_demuxables.firstObject.options;
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
    for (id<SGDemuxable> obj in self->_demuxables) {
        NSError *error = [obj open];
        if (error) {
            return error;
        }
    }
    CMTime duration = kCMTimeZero;
    NSMutableArray<SGTrack *> *tracks = [NSMutableArray array];
    for (id<SGDemuxable> obj in self->_demuxables) {
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
    self->_timeStamps = [[SGPointerMap alloc] init];
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
    NSError * ret = nil;
    while (YES) {
        id<SGDemuxable> demuxable = nil;
        CMTime minimum = kCMTimePositiveInfinity;
        for (id<SGDemuxable> obj in self->_demuxables) {
            if ([self->_finishedDemuxables containsObject:obj]) {
                continue;
            }
            NSValue *value = [self->_timeStamps objectForKey:obj];
            if (!value) {
                demuxable = obj;
                break;
            }
            CMTime t = kCMTimePositiveInfinity;
            [value getValue:&t];
            if (CMTimeCompare(t, minimum) < 0) {
                minimum = t;
                demuxable = obj;
            }
        }
        if (!demuxable) {
            return SGECreateError(SGErrorCodeMutilDemuxerEndOfFile,
                                  SGOperationCodeMutilDemuxerNext);
        }
        ret = [demuxable nextPacket:packet];
        if (ret) {
            if (ret.code == SGErrorImmediateExitRequested) {
                break;
            }
            [self->_finishedDemuxables addObject:demuxable];
            continue;
        }
        CMTime t = (*packet).decodeTimeStamp;
        [self->_timeStamps setObject:[NSValue value:&t withObjCType:@encode(CMTime)] forKey:demuxable];
        break;
    }
    return ret;
}

@end
