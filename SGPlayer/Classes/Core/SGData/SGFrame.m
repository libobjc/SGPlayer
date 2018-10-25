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
    _timeStamp = kCMTimeZero;
    _decodeTimeStamp = kCMTimeZero;
    _duration = kCMTimeZero;
    _size = 0;
}

- (void)configurateWithStream:(SGStream *)stream
{
    _stream = stream;
    _timeStamp = SGCMTimeMakeWithTimebase(self.core->best_effort_timestamp, stream.timebase);
    _decodeTimeStamp = SGCMTimeMakeWithTimebase(self.core->pkt_dts, stream.timebase);
    _duration = SGCMTimeMakeWithTimebase(self.core->pkt_duration, stream.timebase);
    _size = self.core->pkt_size;
}

@end
