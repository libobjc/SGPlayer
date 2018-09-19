//
//  SGPacketReader.m
//  SGPlayer iOS
//
//  Created by Single on 2018/9/19.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPacketReader.h"

@implementation SGPacketReader

- (BOOL)open
{
    return NO;
}

- (BOOL)close
{
    return NO;
}

- (BOOL)seekable
{
    return NO;
}

- (BOOL)seekableToTime:(CMTime)time
{
    return NO;
}

- (BOOL)seekToTime:(CMTime)time
{
    return NO;
}

- (BOOL)seekToTime:(CMTime)time completionHandler:(void(^)(CMTime time, NSError * error))completionHandler
{
    return NO;
}

- (NSError *)nextPacket:(SGPacket *)packet
{
    return nil;
}

@end
