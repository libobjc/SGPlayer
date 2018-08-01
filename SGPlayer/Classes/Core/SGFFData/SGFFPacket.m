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

@end

@implementation SGFFPacket

SGFFObjectPoolItemLockingImplementation

- (instancetype)init
{
    if (self = [super init])
    {
        NSLog(@"%s", __func__);
        _corePacket = av_packet_alloc();
        _position = kCMTimeZero;
        _duration = kCMTimeZero;
        _size = 0;
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

- (int)index
{
    return _corePacket->stream_index;
}

- (void)fillWithTimebase:(CMTime)timebase
{
    if (_corePacket)
    {
        if (_corePacket->pts != AV_NOPTS_VALUE) {
            _position = SGTimeMultiply(timebase, _corePacket->pts);
        } else {
            _position = SGTimeMultiply(timebase, _corePacket->dts);
        }
        _duration = SGTimeMultiply(timebase, _corePacket->duration);
        _size = _corePacket->size;
    }
}

- (void)clear
{
    _position = kCMTimeZero;
    _duration = kCMTimeZero;
    _size = 0;
    if (_corePacket)
    {
        av_packet_unref(_corePacket);
    }
}

@end
