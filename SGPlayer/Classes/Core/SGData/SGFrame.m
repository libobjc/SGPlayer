//
//  SGFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGFrame+Internal.h"
#import "SGObjectPool.h"

@interface SGFrame ()

{
    NSLock *_lock;
    NSUInteger _lockingCount;
}

@end

@implementation SGFrame

@synthesize reuseName = _reuseName;

- (instancetype)init
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_core = av_frame_alloc();
        self->_coreptr = self->_core;
        [self clear];
    }
    return self;
}

- (void)dealloc
{
    NSAssert(self->_lockingCount == 0, @"SGFrame, Invalid locking count");
    [self clear];
    if (self->_core) {
        av_frame_free(&self->_core);
        self->_core = nil;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p>, track: %d, pts: %f, end: %f, duration: %f",
            NSStringFromClass(self.class), self,
            (int)self->_track.index,
            CMTimeGetSeconds(self->_timeStamp),
            CMTimeGetSeconds(CMTimeAdd(self->_timeStamp, self->_duration)),
            CMTimeGetSeconds(self->_duration)];
}

#pragma mark - Setter & Getter

- (SGMediaType)type
{
    return SGMediaTypeUnknown;
}

#pragma mark - Data

- (void)lock
{
    [self->_lock lock];
    self->_lockingCount += 1;
    [self->_lock unlock];
}

- (void)unlock
{
    [self->_lock lock];
    self->_lockingCount -= 1;
    BOOL comeback = self->_lockingCount == 0;
    [self->_lock unlock];
    if (comeback) {
        [[SGObjectPool sharedPool] comeback:self];
    }
}

- (void)clear
{
    if (self->_core) {
        av_frame_unref(self->_core);
    }
    self->_size = 0;
    self->_track = nil;
    self->_duration = kCMTimeZero;
    self->_timeStamp = kCMTimeZero;
    self->_decodeTimeStamp = kCMTimeZero;
    self->_codecDescriptor = nil;
}

#pragma mark - Control

- (void)fill
{
    AVFrame *frame = self->_core;
    AVRational timebase = self->_codecDescriptor.timebase;
    SGCodecDescriptor *cd = self->_codecDescriptor;
    self->_size = frame->pkt_size;
    self->_track = cd.track;
    self->_metadata = cd.metadata;
    CMTime duration = CMTimeMake(frame->pkt_duration * timebase.num, timebase.den);
    CMTime timeStamp = CMTimeMake(frame->best_effort_timestamp * timebase.num, timebase.den);
    CMTime decodeTimeStamp = CMTimeMake(frame->pkt_dts * timebase.num, timebase.den);
    self->_duration = [cd convertDuration:duration];
    self->_timeStamp = [cd convertTimeStamp:timeStamp];
    self->_decodeTimeStamp = [cd convertTimeStamp:decodeTimeStamp];
}

- (void)fillWithTimeStamp:(CMTime)timeStamp decodeTimeStamp:(CMTime)decodeTimeStamp duration:(CMTime)duration
{
    AVFrame *frame = self->_core;
    SGCodecDescriptor *cd = self->_codecDescriptor;
    self->_size = frame->pkt_size;
    self->_track = cd.track;
    self->_metadata = cd.metadata;
    self->_duration = duration;
    self->_timeStamp = timeStamp;
    self->_decodeTimeStamp = decodeTimeStamp;
}

@end
