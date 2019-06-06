//
//  SGPacket.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPacket.h"
#import "SGPacket+Internal.h"
#import "SGObjectPool.h"

@interface SGPacket ()

{
    NSLock *_lock;
    uint64_t _lockingCount;
}

@end

@implementation SGPacket

@synthesize reuseName = _reuseName;

- (instancetype)init
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_core = av_packet_alloc();
        self->_coreptr = self->_core;
        [self clear];
    }
    return self;
}

- (void)dealloc
{
    NSAssert(self->_lockingCount == 0, @"SGPacket, Invalid locking count");
    [self clear];
    if (self->_core) {
        av_packet_free(&self->_core);
        self->_core = nil;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p>, track: %ld, pts: %f, end: %f, duration: %f",
            NSStringFromClass(self.class), self,
            self->_codecDescription.track.index,
            CMTimeGetSeconds(self->_timeStamp),
            CMTimeGetSeconds(CMTimeAdd(self->_timeStamp, self->_duration)),
            CMTimeGetSeconds(self->_duration)];
}

#pragma mark - Setter & Getter

+ (NSString *)commonReuseName
{
    static NSString *ret = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ret = NSStringFromClass(self.class);
    });
    return ret;
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
        av_packet_unref(self->_core);
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
    AVPacket *pkt = self->_core;
    AVRational timebase = self->_codecDescription.timebase;
    SGCodecDescription *codecDescription = self->_codecDescription;
    if (pkt->pts == AV_NOPTS_VALUE) {
        pkt->pts = pkt->dts;
    }
    self->_size = pkt->size;
    self->_track = codecDescription.track;
    self->_duration = CMTimeMake(pkt->duration * timebase.num, timebase.den);
    self->_timeStamp = CMTimeMake(pkt->pts * timebase.num, timebase.den);
    self->_decodeTimeStamp = CMTimeMake(pkt->dts * timebase.num, timebase.den);
    for (SGTimeLayout *obj in codecDescription.timeLayouts) {
        self->_duration = [obj convertDuration:self->_duration];
        self->_timeStamp = [obj convertTimeStamp:self->_timeStamp];
        self->_decodeTimeStamp = [obj convertTimeStamp:self->_decodeTimeStamp];
    }
}

@end
