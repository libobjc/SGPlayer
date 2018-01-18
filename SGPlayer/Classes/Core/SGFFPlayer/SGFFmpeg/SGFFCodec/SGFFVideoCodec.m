//
//  SGFFVideoCodec.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoCodec.h"

@implementation SGFFVideoCodec

- (void)putPacket:(AVPacket)packet
{
    
}

- (void)close
{
    if (self.codecContext)
    {
        avcodec_close(self.codecContext);
        self.codecContext = nil;
    }
}

- (long long)duration
{
    return [self packetDuration] + [self frameDuration];
}

- (long long)packetDuration
{
    return 0;
}

- (long long)frameDuration
{
    return 0;
}

- (long long)size
{
    return [self packetSize] + [self frameSize];
}

- (long long)packetSize
{
    return 0;
}

- (long long)frameSize
{
    return 0;
}

@end
