//
//  SGFFOutputSync.m
//  SGPlayer
//
//  Created by Single on 2018/1/30.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFOutputSync.h"
#import <AVFoundation/AVFoundation.h>

@implementation SGFFOutputSync

- (long long)calculateVideoPositionWithTimebase:(SGFFTimebase)timebase nextVSyncTimestamp:(NSTimeInterval)nextVSyncTimestamp
{
    SGFFTime audioTime = [self.audioOutput currentTime];
    NSTimeInterval position = SGFFTimeGetSeconds(audioTime);
    NSTimeInterval interval = MAX(nextVSyncTimestamp - CACurrentMediaTime(), 0);
    return SGFFSecondsConvertToTimestamp(position + interval, timebase);
}

@end
