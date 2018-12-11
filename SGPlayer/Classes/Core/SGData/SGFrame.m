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
    self->_codecDescription = nil;
}

#pragma mark - Control

- (void)fill
{
    AVFrame *frame = self->_core;
    AVRational timebase = self->_codecDescription.timebase;
    SGCodecDescription *codecDescription = self->_codecDescription;
    self->_size = frame->pkt_size;
    self->_track = codecDescription.track;
    self->_duration = CMTimeMake(frame->pkt_duration * timebase.num, timebase.den);
    self->_timeStamp = CMTimeMake(frame->best_effort_timestamp * timebase.num, timebase.den);
    self->_decodeTimeStamp = CMTimeMake(frame->pkt_dts * timebase.num, timebase.den);
    for (SGTimeLayout *obj in codecDescription.timeLayouts) {
        self->_duration = [obj convertDuration:self->_duration];
        self->_timeStamp = [obj convertTimeStamp:self->_timeStamp];
        self->_decodeTimeStamp = [obj convertTimeStamp:self->_decodeTimeStamp];
    }
}

@end
