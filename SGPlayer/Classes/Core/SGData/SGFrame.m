//
//  SGFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGFrame+Private.h"

@interface SGFrame ()

@property (nonatomic, assign) AVFrame * core;
@property (nonatomic, assign) void * coreptr;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, assign) NSInteger lockingCount;

@end

@implementation SGFrame

- (instancetype)init
{
    if (self = [super init])
    {
        self.coreLock = [[NSLock alloc] init];
        self.core = av_frame_alloc();
        self.coreptr = self.core;
        [self clear];
    }
    return self;
}

- (void)dealloc
{
    NSAssert(self.lockingCount <= 0, @"SGFrame, must be unlocked before release");
    
    [self clear];
    if (self.core)
    {
        av_frame_free(&_core);
        _core = NULL;
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
        av_frame_unref(self.core);
    }
    _stream = nil;
    self.timebase = kCMTimeZero;
    self.scale = CMTimeMake(1, 1);
    self.startTime = kCMTimeZero;
    self.timeRange = kCMTimeRangeZero;
    self.timeStamp = kCMTimeZero;
    self.decodeTimeStamp = kCMTimeZero;
    self.duration = kCMTimeZero;
    self.originalTimeStamp = kCMTimeZero;
    self.originalDecodeTimeStamp = kCMTimeZero;
    self.originalDuration = kCMTimeZero;
    self.size = 0;
}

- (void)configurateWithStream:(SGStream *)stream
{
    _stream = stream;
    self.timebase = stream.timebase;
    self.scale = CMTimeMake(1, 1);
    self.startTime = kCMTimeZero;
    self.timeRange = CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity);
    self.originalTimeStamp = SGCMTimeMakeWithTimebase(self.core->best_effort_timestamp, self.timebase);
    self.originalDecodeTimeStamp = SGCMTimeMakeWithTimebase(self.core->pkt_dts, self.timebase);
    self.originalDuration = SGCMTimeMakeWithTimebase(self.core->pkt_duration, self.timebase);
    CMTime offset = CMTimeSubtract(self.startTime, SGCMTimeMultiply(self.timeRange.start, self.scale));
    self.timeStamp = CMTimeAdd(offset, SGCMTimeMultiply(self.originalTimeStamp, self.scale));
    self.decodeTimeStamp = CMTimeAdd(offset, SGCMTimeMultiply(self.originalDecodeTimeStamp, self.scale));
    self.duration = SGCMTimeMultiply(self.originalDuration, self.scale);
    self.size = self.core->pkt_size;
}

@end
