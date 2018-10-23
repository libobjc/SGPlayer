//
//  SGPacket.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPacket.h"
#import "SGPacket+Private.h"

@interface SGPacket ()

@property (nonatomic, assign) AVPacket * core;
@property (nonatomic, assign) void * coreptr;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, assign) NSInteger lockingCount;

@end

@implementation SGPacket

- (instancetype)init
{
    if (self = [super init])
    {
        self.coreLock = [[NSLock alloc] init];
        self.core = av_packet_alloc();
        self.coreptr = self.core;
        [self clear];
    }
    return self;
}

- (void)dealloc
{
    NSAssert(self.lockingCount <= 0, @"SGPacket, must be unlocked before release");
    
    [self clear];
    if (self.core)
    {
        av_packet_free(&_core);
        self.core = nil;
    }
    self.coreptr = nil;
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
    if (self.lockingCount <= 0)
    {
        self.lockingCount = 0;
        [[SGObjectPool sharePool] comeback:self];
    }
}

- (void)clear
{
    if (self.core)
    {
        av_packet_unref(self.core);
    }
    _stream = nil;
    _timebase = kCMTimeZero;
    _scale = CMTimeMake(1, 1);
    _startTime = kCMTimeZero;
    _timeRange = kCMTimeRangeZero;
    _timeStamp = kCMTimeZero;
    _decodeTimeStamp = kCMTimeZero;
    _duration = kCMTimeZero;
    _originalTimeStamp = kCMTimeZero;
    _originalDecodeTimeStamp = kCMTimeZero;
    _originalDuration = kCMTimeZero;
    _size = 0;
    _keyFrame = NO;
}

- (void)configurateWithStream:(SGStream *)stream
{
    _stream = stream;
    _timebase = _stream.timebase;
    _scale = CMTimeMake(1, 1);
    _startTime = kCMTimeZero;
    _timeRange = CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity);
    _originalTimeStamp = SGCMTimeMakeWithTimebase(self.core->pts != AV_NOPTS_VALUE ? self.core->pts : self.core->dts, self.timebase);
    _originalDecodeTimeStamp = SGCMTimeMakeWithTimebase(self.core->dts, self.timebase);
    _originalDuration = SGCMTimeMakeWithTimebase(self.core->duration, self.timebase);
    CMTime offset = CMTimeSubtract(self.startTime, SGCMTimeMultiply(self.timeRange.start, self.scale));
    _timeStamp = CMTimeAdd(offset, SGCMTimeMultiply(self.originalTimeStamp, self.scale));
    _decodeTimeStamp = CMTimeAdd(offset, SGCMTimeMultiply(self.originalDecodeTimeStamp, self.scale));
    _duration = SGCMTimeMultiply(self.originalDuration, self.scale);
    _size = self.core->size;
    _keyFrame = self.core->flags & AV_PKT_FLAG_KEY;
}

@end
