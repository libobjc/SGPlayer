//
//  SGTime.m
//  SGPlayer
//
//  Created by Single on 2018/6/13.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGTime.h"

BOOL SGCMTimeIsValid(CMTime time, BOOL infinity)
{
    return
    CMTIME_IS_VALID(time) &&
    (infinity || (!CMTIME_IS_NEGATIVE_INFINITY(time) &&
                  !CMTIME_IS_POSITIVE_INFINITY(time)));
}

CMTime SGCMTimeValidate(CMTime time, CMTime defaultTime, BOOL infinity)
{
    if (SGCMTimeIsValid(time, infinity)) {
        return time;
    }
    NSCAssert(SGCMTimeIsValid(defaultTime, infinity), @"Invalid Default Time.");
    return defaultTime;
}

CMTime SGCMTimeMakeWithSeconds(Float64 seconds)
{
    return CMTimeMakeWithSeconds(seconds, 1000000);
}

CMTime SGCMTimeMultiply(CMTime time, CMTime multiplier)
{
    int64_t maxV = ABS(time.value == 0 ? INT64_MAX : INT64_MAX / time.value);
    int32_t maxT = ABS(time.timescale == 0 ? INT32_MAX : INT32_MAX / time.timescale);
    if (multiplier.value > maxV || multiplier.value < -maxV || multiplier.timescale > maxT || multiplier.timescale < -maxT) {
        return CMTimeMultiplyByFloat64(time, CMTimeGetSeconds(multiplier));
    }
    return CMTimeMake(time.value * multiplier.value, time.timescale * multiplier.timescale);
}

CMTime SGCMTimeDivide(CMTime time, CMTime divisor)
{
    int64_t maxV = ABS(time.value == 0 ? INT64_MAX : INT64_MAX / time.value);
    int32_t maxT = ABS(time.timescale == 0 ? INT32_MAX : INT32_MAX / time.timescale);
    if (divisor.timescale > maxV || divisor.timescale < -maxV || divisor.value > maxT || divisor.value < -maxT) {
        return CMTimeMultiplyByFloat64(time, 1.0 / CMTimeGetSeconds(divisor));
    }
    return CMTimeMake(time.value * divisor.timescale, time.timescale * (int32_t)divisor.value);
}

CMTimeRange SGCMTimeRangeFit(CMTimeRange timeRange)
{
    return CMTimeRangeMake(SGCMTimeValidate(timeRange.start, kCMTimeNegativeInfinity, YES),
                           SGCMTimeValidate(timeRange.duration, kCMTimePositiveInfinity, YES));
}
