//
//  SGTimeTransform.m
//  SGPlayer
//
//  Created by Single on 2018/11/15.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGTimeTransform.h"

@implementation SGTimeTransform

- (instancetype)init
{
    if (self = [super init]) {
        self.start = kCMTimeInvalid;
        self.scale = kCMTimeInvalid;
    }
    return self;
}

- (CMTime)applyToTimeStamp:(CMTime)timeStamp
{
    if (CMTIME_IS_VALID(self.start)) {
        return CMTimeAdd(timeStamp, self.start);
    }
    return timeStamp;
}

- (CMTime)applyToDuration:(CMTime)duration
{
    return duration;
}

@end
