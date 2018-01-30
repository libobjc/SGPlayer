//
//  SGFFSyncClock.m
//  SGPlayer
//
//  Created by Single on 2018/1/29.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFSyncClock.h"

@implementation SGFFSyncClock

- (void)outputDidUpdateCurrentTime:(id <SGFFOutput>)output
{
    NSLog(@"%f", SGFFTimeGetSeconds(output.currentTime));
}

@end
