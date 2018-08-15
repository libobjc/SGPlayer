//
//  SGTime.m
//  SGPlayer
//
//  Created by Single on 2018/6/13.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGTime.h"

AVRational SGRationalValidate(AVRational rational, AVRational defaultRational)
{
    if (rational.num > 0 && rational.den > 0)
    {
        return rational;
    }
    return defaultRational;
}

CMTime SGCMTimeMakeWithRational(int64_t timeStamp, AVRational timebase)
{
    int64_t maxV = ABS(timeStamp == 0 ? INT64_MAX : INT64_MAX / timeStamp);
    if (timebase.num > maxV || timebase.num < -maxV)
    {
        return CMTimeMake(timeStamp, timebase.den / timebase.num);
    }
    return CMTimeMake(timebase.num * timeStamp, timebase.den);
}

CMTime SGCMTimeMakeWithSeconds(Float64 seconds)
{
    return CMTimeMakeWithSeconds(seconds, 1000000);
}

CMTime SGCMTimeMultiply(CMTime time, CMTime multiplier)
{
    int64_t maxV = ABS(time.value == 0 ? INT64_MAX : INT64_MAX / time.value);
    int32_t maxT = ABS(time.timescale == 0 ? INT32_MAX : INT32_MAX / time.timescale);
    if (multiplier.value > maxV || multiplier.value < -maxV || multiplier.timescale > maxT || multiplier.timescale < -maxT)
    {
        return CMTimeMultiplyByFloat64(time, CMTimeGetSeconds(multiplier));
    }
    return CMTimeMake(time.value * multiplier.value, time.timescale * multiplier.timescale);
}

CMTime SGCMTimeDivide(CMTime time, CMTime divisor)
{
    int64_t maxV = ABS(time.value == 0 ? INT64_MAX : INT64_MAX / time.value);
    int32_t maxT = ABS(time.timescale == 0 ? INT32_MAX : INT32_MAX / time.timescale);
    if (divisor.timescale > maxV || divisor.timescale < -maxV || divisor.value > maxT || divisor.value < -maxT)
    {
        return CMTimeMultiplyByFloat64(time, 1.0 / CMTimeGetSeconds(divisor));
    }
    return CMTimeMake(time.value * divisor.timescale, time.timescale * (int32_t)divisor.value);
}
