//
//  SGPacket.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPacket.h"
#import "SGPacket+Internal.h"

@interface SGPacket ()

{
    AVPacket * _packet;
    NSLock * _lock;
    uint64_t _locking_count;
}

@property (nonatomic, copy) SGCodecDescription * codecDescription;

@end

@implementation SGPacket

- (instancetype)init
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_packet = av_packet_alloc();
        [self clear];
    }
    return self;
}

- (void)dealloc
{
    NSAssert(self->_locking_count == 0, @"SGPacket, Invalid locking count");
    [self clear];
    if (self->_packet) {
        av_packet_free(&self->_packet);
        self->_packet = nil;
    }
}

- (void *)coreptr {return self->_packet;}
- (AVPacket *)core {return self->_packet;}

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
    if (self->_packet) {
        av_packet_unref(self->_packet);
    }
    self->_size = 0;
    self->_index = -1;
    self->_duration = kCMTimeZero;
    self->_timeStamp = kCMTimeZero;
    self->_decodeTimeStamp = kCMTimeZero;
    self->_codecDescription = nil;
}

- (void)fill
{
    AVPacket * pkt = self->_packet;
    AVRational timebase = self->_codecDescription.timebase;
    SGCodecDescription * cd = self->_codecDescription;
    if (pkt->pts == AV_NOPTS_VALUE) {
        pkt->pts = pkt->dts;
    }
    self->_size = pkt->size;
    self->_index = cd.index;
    self->_duration = CMTimeMake(pkt->duration * timebase.num, timebase.den);
    self->_timeStamp = CMTimeMake(pkt->pts * timebase.num, timebase.den);
    self->_decodeTimeStamp = CMTimeMake(pkt->dts * timebase.num, timebase.den);
    for (SGTimeLayout * obj in cd.timeLayouts) {
        self->_duration = [obj convertDuration:self->_duration];
        self->_timeStamp = [obj convertTimeStamp:self->_timeStamp];
        self->_decodeTimeStamp = [obj convertTimeStamp:self->_decodeTimeStamp];
    }
}

@end
