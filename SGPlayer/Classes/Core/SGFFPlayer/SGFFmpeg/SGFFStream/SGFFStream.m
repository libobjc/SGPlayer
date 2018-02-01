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

- (id <SGFFOutputRender>)getOutputRender
{
    return [self.codec getOutputRender];
}

- (id <SGFFOutputRender>)getOutputRenderWithPositionHandler:(BOOL (^)(long long * current, long long * expect))positionHandler
{
    return [self.codec getOutputRenderWithPositionHandler:positionHandler];
}

@end
