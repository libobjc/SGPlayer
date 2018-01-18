//
//  SGFFTime.m
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFTime.h"

AVRational SGFFTimebaseValidate(AVRational timebase, int num, int den)
{
    if (timebase.num > 0 && timebase.den > 0) {
        return timebase;
    }
    AVRational result;
    result.num = num;
    result.den = den;
    return result;
}
