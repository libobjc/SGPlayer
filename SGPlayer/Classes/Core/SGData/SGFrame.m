//
//  SGFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"

@interface SGFrame ()

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, assign) NSInteger lockingCount;

@end

@implementation SGFrame

- (SGMediaType)mediaType
{
    return SGMediaTypeUnknown;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.coreLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self clear];
    NSAssert(self.lockingCount <= 0, @"SGFrame, must be unlocked before release");
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
    self.timebase = kCMTimeZero;
    self.scale = CMTimeMake(1, 1);
    self.startTime = kCMTimeZero;
    self.timeStamp = kCMTimeZero;
    self.decodeTimeStamp = kCMTimeZero;
    self.duration = kCMTimeZero;
    self.originalTimeStamp = kCMTimeZero;
    self.originalDecodeTimeStamp = kCMTimeZero;
    self.originalDuration = kCMTimeZero;
    self.size = 0;
}

@end
