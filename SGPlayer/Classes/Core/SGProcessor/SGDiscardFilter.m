//
//  SGDiscardFilter.m
//  SGPlayer iOS
//
//  Created by Single on 2018/9/6.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDiscardFilter.h"

@interface SGDiscardFilter ()

@property (nonatomic) CMTime lastTimeStamp;

@end

@implementation SGDiscardFilter

- (instancetype)init
{
    if (self = [super init])
    {
        self.minimumInterval = kCMTimeZero;
        [self flush];
    }
    return self;
}

- (BOOL)discardWithTimeStamp:(CMTime)timeStamp
{
    CMTime interval = CMTimeSubtract(timeStamp, self.lastTimeStamp);
    if (CMTimeCompare(interval, self.minimumInterval) < 0)
    {
        return YES;
    }
    self.lastTimeStamp = timeStamp;
    return NO;
}

- (void)flush
{
    self.lastTimeStamp = kCMTimeNegativeInfinity;
}

@end
