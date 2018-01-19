//
//  SGFFTime.m
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFTime.h"

SGFFTimebase SGFFTimebaseValidate(int num, int den, int num_def, int den_def)
{
    if (num > 0 && den > 0)
    {
        SGFFTimebase timebase = {num, den};
        return timebase;
    }
    else
    {
        SGFFTimebase timebase = {num_def, den_def};
        return timebase;
    }
}
