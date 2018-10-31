//
//  SGTime.m
//  SGPlayer
//
//  Created by Single on 2018/6/13.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGTime.h"

CMTime SGCMTimeValidate(CMTime time, CMTime defaultTime)
{
    if (CMTIME_IS_INVALID(defaultTime)) {
        return time;
    }
    if (CMTIME_IS_INVALID(time)) {
        return defaultTime;
    }
    if (CMTimeCompare(time, kCMTimeZero) <= 0) {
        return defaultTime;
    }
    return time;
}

CMTime SGCMTimeMakeWithTimebase(int64_t timeStamp, CMTime timebase)
{
    int64_t maxV = ABS(timeStamp == 0 ? INT64_MAX : INT64_MAX / timeStamp);
    if (timebase.value > maxV || timebase.value < -maxV) {
        return CMTimeMake(timeStamp, timebase.timescale / timebase.value);
    }
    return CMTimeMake(timebase.value * timeStamp, timebase.timescale);
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
