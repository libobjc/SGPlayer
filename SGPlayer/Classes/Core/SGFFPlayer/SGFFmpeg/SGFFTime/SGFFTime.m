//
//  SGFFTime.m
//  SGPlayer
//
//  Created by Single on 2018/6/13.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFFTime.h"

CMTime SGFFTimeValidate(CMTime time, CMTime defaultTime)
{
    if (CMTIME_IS_INVALID(defaultTime))
    {
        return time;
    }
    if (CMTIME_IS_INVALID(time))
    {
        return defaultTime;
    }
    if (CMTimeCompare(time, kCMTimeZero) <= 0)
    {
        return defaultTime;
    }
    return time;
}

CMTime SGFFTimeMultiply(CMTime time, int64_t multiplier)
{
    return CMTimeMake(time.value * multiplier, time.timescale);
}

CMTime SGFFTimeMultiplyByRatio(CMTime time, int64_t multiplier, int64_t divisor)
{
    return CMTimeMake(time.value * multiplier / divisor, time.timescale);
}

CMTime SGFFTimeMakeWithSeconds(Float64 seconds)
{
    return CMTimeMakeWithSeconds(seconds, 10000);
}
