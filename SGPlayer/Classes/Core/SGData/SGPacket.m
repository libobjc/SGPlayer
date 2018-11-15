//
//  SGPacket.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPacket.h"
#import "SGPacket+Internal.h"
#import "SGTrack+Internal.h"

@interface SGPacket ()

@property (nonatomic) AVPacket * core;
@property (nonatomic) void * core_ptr;
@property (nonatomic) void * codecpar_ptr;
@property (nonatomic) AVCodecParameters * codecpar;
@property (nonatomic) AVRational timebase;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, assign) NSInteger lockingCount;

@end

@implementation SGPacket

- (instancetype)init
{
    if (self = [super init]) {
        self.coreLock = [[NSLock alloc] init];
        self.core = av_packet_alloc();
        self.core_ptr = self.core;
        [self clear];
    }
    return self;
}

- (void)dealloc
{
    NSAssert(self.lockingCount <= 0, @"SGPacket, must be unlocked before release");
    
    [self clear];
    if (self.core) {
        av_packet_free(&_core);
        self.core = nil;
    }
    self.core_ptr = nil;
}

- (void)lock
{
    [self.coreLock lock];
    self.lockingCount++;
    [self.coreLock unlock];
}

- (void)unlock
{
    [self.coreLock lock];
    self.lockingCount--;
    [self.coreLock unlock];
    if (self.lockingCount <= 0) {
        self.lockingCount = 0;
        [[SGObjectPool sharePool] comeback:self];
    }
}

- (void)clear
{
    if (self.core) {
        av_packet_unref(self.core);
    }
    _type = SGMediaTypeUnknown;
    _timeStamp = kCMTimeZero;
    _decodeTimeStamp = kCMTimeZero;
    _duration = kCMTimeZero;
    _index = -1;
    _size = 0;
    
    _codecpar = nil;
    _codecpar_ptr = nil;
    _timebase = av_make_q(0, 1);
}

- (void)configurateWithTrack:(SGTrack *)track
{
    if (self.core->pts == AV_NOPTS_VALUE) {
        self.core->pts = self.core->dts;
    }
    _type = track.type;
    _timeStamp = SGCMTimeMakeWithTimebase(self.core->pts, track.timebase);
    _decodeTimeStamp = SGCMTimeMakeWithTimebase(self.core->dts, track.timebase);
    _duration = SGCMTimeMakeWithTimebase(self.core->duration, track.timebase);
    _index = track.index;
    _size = self.core->size;
    
    _codecpar = track.core->codecpar;
    _codecpar_ptr = track.core->codecpar;
    _timebase = track.core->time_base;
}

- (void)applyTransform:(SGTimeTransform *)transform
{
    if (!transform) {
        return;
    }
    _timeStamp = [transform applyToTimeStamp:_timeStamp];
    _decodeTimeStamp = [transform applyToTimeStamp:_decodeTimeStamp];
    _duration = [transform applyToDuration:_duration];
}

@end
