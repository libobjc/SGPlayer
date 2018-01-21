//
//  SGFFTime.h
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct SGFFTimebase {
    int num;
    int den;
} SGFFTimebase;

SGFFTimebase SGFFTimebaseIdentity(void);
SGFFTimebase SGFFTimebaseValidate(int num, int den, int num_def, int den_def);
double SGFFTimebaseConvertToSeconds(long long timestamp, SGFFTimebase timebase);
