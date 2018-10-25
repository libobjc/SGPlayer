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
    _timeStamp = kCMTimeZero;
    _decodeTimeStamp = kCMTimeZero;
    _duration = kCMTimeZero;
    _size = 0;
}

- (void)configurateWithStream:(SGStream *)stream
{
    if (self.core->pts == AV_NOPTS_VALUE) {
        self.core->pts = self.core->dts;
    }
    _stream = stream;
    _timeStamp = SGCMTimeMakeWithTimebase(self.core->pts, stream.timebase);
    _decodeTimeStamp = SGCMTimeMakeWithTimebase(self.core->dts, stream.timebase);
    _duration = SGCMTimeMakeWithTimebase(self.core->duration, stream.timebase);
    _size = self.core->size;
}

@end
