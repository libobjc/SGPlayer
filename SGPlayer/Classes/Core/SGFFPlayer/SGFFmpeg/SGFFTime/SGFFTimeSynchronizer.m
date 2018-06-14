//
//  SGFFTimeSynchronizer.m
//  SGPlayer
//
//  Created by Single on 2018/6/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFFTimeSynchronizer.h"

@interface SGFFTimeSynchronizer ()

@property (nonatomic, assign) CMTime postPosition;
@property (nonatomic, assign) CMTime postDuration;
@property (nonatomic, assign) CMTime postMediaTime;

@end

@implementation SGFFTimeSynchronizer

- (instancetype)init
{
    if (self = [super init])
    {
        _rate = CMTimeMake(1, 1);
        _postPosition = kCMTimeZero;
        _postDuration = kCMTimeZero;
        _postMediaTime = kCMTimeZero;
    }
    return self;
}

- (void)postPosition:(CMTime)position duration:(CMTime)duration
{
    self.postPosition = position;
    self.postDuration = duration;
    self.postMediaTime = SGFFTimeMakeWithSeconds(CACurrentMediaTime());
}

- (CMTime)position
{
    if (CMTIME_IS_INVALID(self.postDuration))
    {
        return self.postPosition;
    }
    if (CMTimeCompare(self.postDuration, kCMTimeZero) <= 0)
    {
        return self.postPosition;
    }
    CMTime currentMediaTime = SGFFTimeMakeWithSeconds(CACurrentMediaTime());
    CMTime interval = CMTimeMinimum(self.postDuration, CMTimeSubtract(currentMediaTime, self.postMediaTime));
    CMTime ret = CMTimeAdd(self.postPosition, interval);
    return ret;
}

@end
