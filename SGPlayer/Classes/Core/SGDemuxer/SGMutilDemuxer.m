//
//  SGMutilDemuxer.m
//  SGPlayer
//
//  Created by Single on 2018/11/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGMutilDemuxer.h"
#import "SGTrack+Internal.h"
#import "SGPointerMap.h"
#import "SGError.h"

@interface SGMutilDemuxer ()

@property (nonatomic, strong) SGPointerMap * timeStamps;
@property (nonatomic, strong) NSMutableArray <id <SGDemuxable>> * demuxablesFinished;
@property (nonatomic, strong) NSArray <id <SGDemuxable>> * demuxables;
@property (nonatomic, copy) NSArray <SGTrack *> * tracks;
@property (nonatomic, copy) NSDictionary * metadata;
@property (nonatomic) CMTime duration;

@end

@implementation SGMutilDemuxer

- (instancetype)initWithDemuxables:(NSArray <id <SGDemuxable>> *)demuxables
{
    if (self = [super init]) {
        self.demuxables = demuxables;
        self.demuxablesFinished = [NSMutableArray array];
    }
    return self;
}

- (void)setDelegate:(id <SGDemuxableDelegate>)delegate
{
    for (id <SGDemuxable> obj in self.demuxables) {
        obj.delegate = delegate;
    }
}

- (id <SGDemuxableDelegate>)delegate
{
    return self.demuxables.firstObject.delegate;
}

- (void)setOptions:(NSDictionary *)options
{
    for (id <SGDemuxable> obj in self.demuxables) {
        obj.options = options;
    }
}

- (NSDictionary *)options
{
    return self.demuxables.firstObject.options;
}

- (NSError *)open
{
    for (id <SGDemuxable> obj in self.demuxables) {
        NSError * error = [obj open];
        if (error) {
            return error;
        }
    }
    CMTime duration = kCMTimeZero;
    NSMutableArray <SGTrack *> * tracks = [NSMutableArray array];
    for (id <SGDemuxable> obj in self.demuxables) {
        duration = CMTimeMaximum(duration, obj.duration);
        [tracks addObjectsFromArray:obj.tracks];
    }
    self.duration = duration;
    self.tracks = [tracks copy];
    NSMutableArray <NSNumber *> * indexes = [NSMutableArray array];
    for (SGTrack * obj in self.tracks) {
        NSAssert(![indexes containsObject:@(obj.index)], @"Invalid Track Indexes");
        [indexes addObject:@(obj.index)];
    }
    self.timeStamps = [[SGPointerMap alloc] init];
    return nil;
}

- (NSError *)close
{
    for (id <SGDemuxable> obj in self.demuxables) {
        [obj close];
    }
    return nil;
}

- (NSError *)seekable
{
    for (id <SGDemuxable> obj in self.demuxables) {
        NSError * error = [obj seekable];
        if (error) {
            return error;
        }
    }
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    for (id <SGDemuxable> obj in self.demuxables) {
        [obj seekToTime:time];
    }
    [self.timeStamps removeAllObjects];
    [self.demuxablesFinished removeAllObjects];
    return nil;
}

- (NSError *)nextPacket:(SGPacket *)packet
{
    while (YES) {
        id <SGDemuxable> demuxable = nil;
        CMTime minimum = kCMTimePositiveInfinity;
        for (id <SGDemuxable> obj in self.demuxables) {
            if ([self.demuxablesFinished containsObject:obj]) {
                continue;
            }
            NSValue * value = [self.timeStamps objectForKey:obj];
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
        if ([demuxable nextPacket:packet]) {
            [self.demuxablesFinished addObject:demuxable];
            continue;
        }
        CMTime t = packet.decodeTimeStamp;
        [self.timeStamps setObject:[NSValue value:&t withObjCType:@encode(CMTime)] forKey:demuxable];
        break;
    }
    return nil;
}

@end
