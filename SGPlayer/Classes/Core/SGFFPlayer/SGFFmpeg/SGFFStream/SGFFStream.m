//
//  SGFFStream.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFStream.h"

@interface SGFFStream ()

@end

@implementation SGFFStream

- (BOOL)open
{
    if (self.codec)
    {
        return [self.codec open];
    }
    return NO;
}

- (void)flush
{
    if (self.codec)
    {
        [self.codec flush];
    }
}

- (void)close
{
    if (self.codec)
    {
        [self.codec close];
        self.codec = nil;
    }
}

- (BOOL)putPacket:(SGFFPacket *)packet
{
    if (self.codec)
    {
        return [self.codec putPacket:packet];
    }
    return NO;
}

- (CMTime)timebase
{
    if (self.coreStream)
    {
        return CMTimeMake(self.coreStream->time_base.num, self.coreStream->time_base.den);
    }
    return kCMTimeZero;
}

@end
