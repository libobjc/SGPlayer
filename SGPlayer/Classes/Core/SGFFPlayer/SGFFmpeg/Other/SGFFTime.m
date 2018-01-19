//
//  SGFFTime.m
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFTime.h"

AVRational SGFFTimebaseValidate(AVRational timebase, AVRational defaultTimebase)
{
    if (timebase.num > 0 && timebase.den > 0) {
        return timebase;
    }
    return defaultTimebase;
}
