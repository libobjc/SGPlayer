//
//  SGCapacity.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/25.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGCapacity.h"

SGCapacity SGCapacityCreate(void)
{
    SGCapacity ret;
    ret.size = 0;
    ret.count = 0;
    ret.duration = kCMTimeZero;
    return ret;
}

SGCapacity SGCapacityAdd(SGCapacity c1, SGCapacity c2)
{
    SGCapacity ret = SGCapacityCreate();
    ret.size = c1.size + c2.size;
    ret.count = c1.count + c2.count;
    ret.duration = CMTimeAdd(c1.duration, c2.duration);
    return ret;
}

SGCapacity SGCapacityMinimum(SGCapacity c1, SGCapacity c2)
{
    if (CMTimeCompare(c1.duration, c2.duration) < 0) {
        return c1;
    } else if (CMTimeCompare(c1.duration, c2.duration) > 0) {
        return c1;
    }
    if (c1.count < c2.count) {
        return c1;
    } else if (c1.count > c2.count) {
        return c2;
    }
    if (c1.size < c2.size) {
        return c1;
    } else if (c1.size > c2.size) {
        return c2;
    }
    return c1;
}

SGCapacity SGCapacityMaximum(SGCapacity c1, SGCapacity c2)
{
    if (CMTimeCompare(c1.duration, c2.duration) < 0) {
        return c2;
    } else if (CMTimeCompare(c1.duration, c2.duration) > 0) {
        return c1;
    }
    if (c1.count < c2.count) {
        return c2;
    } else if (c1.count > c2.count) {
        return c1;
    }
    if (c1.size < c2.size) {
        return c2;
    } else if (c1.size > c2.size) {
        return c1;
    }
    return c1;
}

BOOL SGCapacityIsEqual(SGCapacity c1, SGCapacity c2)
{
    return
    c1.size == c2.size &&
    c1.count == c2.count &&
    CMTimeCompare(c1.duration, c2.duration) == 0;
}

BOOL SGCapacityIsEnough(SGCapacity c1)
{
    /*
    return
    c1.count >= 30 &&
    CMTimeCompare(c1.duration, CMTimeMake(1, 1)) > 0;
     */
    return
    c1.count >= 50000;
}

BOOL SGCapacityIsEmpty(SGCapacity c1)
{
    return
    c1.size == 0 &&
    c1.count == 0 &&
    CMTimeCompare(c1.duration, kCMTimeZero) == 0;
}
