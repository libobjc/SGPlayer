//
//  SGFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGFrame+Internal.h"

@interface SGFrame ()

{
    AVFrame * _frame;
    NSLock * _lock;
    uint64_t _locking_count;
}

@property (nonatomic, copy) SGCodecDescription * codecDescription;

@end

@implementation SGFrame

- (SGMediaType)type
{
    return SGMediaTypeUnknown;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_frame = av_frame_alloc();
        [self clear];
    }
    return self;
}

- (void)dealloc
{
    NSAssert(self->_locking_count == 0, @"SGFrame, Invalid locking count");
    [self clear];
    if (self->_frame) {
        av_frame_free(&self->_frame);
        self->_frame = nil;
    }
}

- (void *)coreptr {return self->_frame;}
- (AVFrame *)core {return self->_frame;}

- (void)lock
{
    [self->_lock lock];
    self->_locking_count += 1;
    [self->_lock unlock];
}

- (void)unlock
{
    [self->_lock lock];
    self->_locking_count -= 1;
    [self->_lock unlock];
    if (self->_locking_count == 0) {
        self->_locking_count = 0;
        [[SGObjectPool sharePool] comeback:self];
    }
}

- (void)clear
{
    if (self->_frame) {
        av_frame_unref(self->_frame);
    }
    self->_size = 0;
    self->_duration = kCMTimeZero;
    self->_timeStamp = kCMTimeZero;
    self->_decodeTimeStamp = kCMTimeZero;
    self->_codecDescription = nil;
}

- (void)fill
{
    AVFrame * frame = self->_frame;
    AVRational timebase = self->_codecDescription.timebase;
    SGCodecDescription * cd = self->_codecDescription;
    self->_size = frame->pkt_size;
    self->_duration = CMTimeMake(frame->pkt_duration * timebase.num, timebase.den);
    self->_timeStamp = CMTimeMake(frame->best_effort_timestamp * timebase.num, timebase.den);
    self->_decodeTimeStamp = CMTimeMake(frame->pkt_dts * timebase.num, timebase.den);
    for (SGTimeLayout * obj in cd.timeLayouts) {
        self->_duration = [obj convertDuration:self->_duration];
        self->_timeStamp = [obj convertTimeStamp:self->_timeStamp];
        self->_decodeTimeStamp = [obj convertTimeStamp:self->_decodeTimeStamp];
    }
}

@end
