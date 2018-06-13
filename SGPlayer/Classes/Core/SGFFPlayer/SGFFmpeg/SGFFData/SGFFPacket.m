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

- (void)fillWithTimebase:(CMTime)timebase
{
    if (_corePacket)
    {
        if (_corePacket->pts != AV_NOPTS_VALUE) {
            _position = SGFFTimeMultiply(timebase, _corePacket->pts);
        } else {
            _position = SGFFTimeMultiply(timebase, _corePacket->dts);
        }
        _duration = SGFFTimeMultiply(timebase, _corePacket->duration);
        _size = _corePacket->size;
    }
}

SGFFObjectPoolItemLockingImplementation

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
