//
//  SGFFFFFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFFFFFrame.h"

@implementation SGFFFFFrame

- (instancetype)init
{
    if (self = [super init])
    {
        NSLog(@"%s", __func__);
        _coreFrame = av_frame_alloc();
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    if (_coreFrame)
    {
        av_frame_free(&_coreFrame);
        _coreFrame = NULL;
    }
}

- (void)fillWithTimebase:(CMTime)timebase packet:(SGFFPacket *)packet
{
    self.position = SGFFTimeMultiply(timebase, av_frame_get_best_effort_timestamp(self.coreFrame));
    self.duration = SGFFTimeMultiply(timebase, av_frame_get_pkt_duration(self.coreFrame));
    self.size = av_frame_get_pkt_size(self.coreFrame);
}

- (void)clear
{
    [super clear];
    if (_coreFrame)
    {
        av_frame_unref(_coreFrame);
    }
}

@end
