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

- (void)open
{
    self.codec.timebase = self.stream->time_base;
    [self.codec open];
}

- (void)close
{
    [self.codec close];
    self.codec = nil;
}

- (void)putPacket:(AVPacket)packet
{
    if (self.codec)
    {
        [self.codec putPacket:packet];
    }
}

@end
