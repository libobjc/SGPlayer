//
//  SGTime.m
//  SGPlayer
//
//  Created by Single on 2018/6/13.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGTime.h"

CMTime SGTimeValidate(CMTime time, CMTime defaultTime)
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

CMTime SGTimeMultiply(CMTime time, int64_t multiplier)
{
    return CMTimeMultiply(time, (int32_t)multiplier);
}

CMTime SGTimeMultiplyByTime(CMTime time, CMTime multiplier)
{
    return SGTimeMultiplyByRatio(time, multiplier.value, multiplier.timescale);
}

CMTime SGTimeMultiplyByRatio(CMTime time, int64_t multiplier, int64_t divisor)
{
    return CMTimeMultiplyByRatio(time, (int32_t)multiplier, (int32_t)divisor);
}

CMTime SGTimeDivide(CMTime time, int64_t divisor)
{
    return SGTimeMultiplyByRatio(time, 1, divisor);
}

CMTime SGTimeDivideByTime(CMTime time, CMTime divisor)
{
    return SGTimeMultiplyByRatio(time, divisor.timescale, divisor.value);
}

CMTime SGTimeDivideByRatio(CMTime time, int64_t divisor, int64_t multiplier)
{
    return CMTimeMultiplyByRatio(time, (int32_t)multiplier, (int32_t)divisor);
}

CMTime SGTimeMakeWithSeconds(Float64 seconds)
{
    return CMTimeMakeWithSeconds(seconds, 1000000);
}
