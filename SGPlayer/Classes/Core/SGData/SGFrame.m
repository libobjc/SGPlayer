//
//  SGFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"

@interface SGFrame ()

@property (nonatomic, assign) NSInteger lockingCount;

@end

@implementation SGFrame

- (SGMediaType)mediaType
{
    return SGMediaTypeUnknown;
}

- (void)dealloc
{
    [self clear];
}

- (void)lock
{
    self.lockingCount++;
}

- (void)unlock
{
    self.lockingCount--;
    if (self.lockingCount <= 0)
    {
        self.lockingCount = 0;
        [[SGObjectPool sharePool] comeback:self];
    }
}

- (void)clear
{
    self.timebase = kCMTimeZero;
    self.offset = kCMTimeZero;
    self.scale = CMTimeMake(1, 1);
    self.timeStamp = kCMTimeZero;
    self.duration = kCMTimeZero;
    self.originalTimeStamp = kCMTimeZero;
    self.originalDuration = kCMTimeZero;
    self.decodeTimeStamp = kCMTimeZero;
    self.size = 0;
}

@end
