//
//  SGFFPacket.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFPacket.h"

@interface SGFFPacket ()

SGFFObjectPoolItemLockingInterface

@property (nonatomic, assign, readonly) AVPacket * corePacket;

@end

@implementation SGFFPacket

- (instancetype)init
{
    if (self = [super init])
    {
        NSLog(@"%s", __func__);
        _corePacket = av_packet_alloc();
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    if (_corePacket)
    {
        av_packet_free(&_corePacket);
        _corePacket = nil;
    }
}

- (void)fill
{
    if (_corePacket)
    {
        if (_corePacket->pts != AV_NOPTS_VALUE) {
            self.position = _corePacket->pts;
        } else {
            self.position = _corePacket->dts;
        }
        self.position = _corePacket->pts;
        self.duration = _corePacket->duration;
        self.size = _corePacket->size;
    }
}

SGFFObjectPoolItemLockingImplementation

- (void)clear
{
    self.position = 0;
    self.duration = 0;
    self.size = 0;
    if (_corePacket)
    {
        av_packet_unref(_corePacket);
    }
}

@end
