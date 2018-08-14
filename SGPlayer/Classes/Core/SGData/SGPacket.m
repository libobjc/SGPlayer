//
//  SGPacket.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPacket.h"

@interface SGPacket ()

SGObjectPoolItemLockingInterface

@end

@implementation SGPacket

SGObjectPoolItemLockingImplementation

- (instancetype)init
{
    if (self = [super init])
    {
        _corePacket = av_packet_alloc();
        _codecpar = NULL;
        _mediaType = SGMediaTypeUnknown;
        _timebase = kCMTimeZero;
        _offset = kCMTimeZero;
        _scale = CMTimeMake(1, 1);
        _timeStamp = kCMTimeZero;
        _originalTimeStamp = kCMTimeZero;
        _duration = kCMTimeZero;
        _dts = kCMTimeZero;
        _size = 0;
    }
    return self;
}

- (void)dealloc
{
    if (_corePacket)
    {
        av_packet_free(&_corePacket);
        _corePacket = nil;
    }
}

- (void)fillWithStream:(SGStream *)stream
{
    [self fillWithStream:stream offset:kCMTimeZero scale:CMTimeMake(1, 1)];
}

- (void)fillWithStream:(SGStream *)stream offset:(CMTime)offset scale:(CMTime)scale
{
    CMTime defaultTimebase = CMTimeMake(1, 1);
    switch (stream.mediaType)
    {
        case SGMediaTypeAudio:
            defaultTimebase = CMTimeMake(1, 44100);
            break;
        case SGMediaTypeVideo:
            defaultTimebase = CMTimeMake(1, 25000);
        default:
            break;
    }
    CMTime timebase = SGTimeValidate(stream.timebase, defaultTimebase);
    _timebase = timebase;
    _codecpar = stream.coreStream->codecpar;
    _mediaType = stream.mediaType;
    _offset = offset;
    _scale = scale;
    _originalTimeStamp = SGTimeMultiply(timebase, _corePacket->pts != AV_NOPTS_VALUE ? _corePacket->pts : _corePacket->dts);
    _timeStamp = CMTimeAdd(self.offset, SGTimeMultiplyByTime(self.originalTimeStamp, self.scale));
    _duration = SGTimeMultiply(timebase, _corePacket->duration);
    _dts = SGTimeMultiply(timebase, _corePacket->dts);
    _size = _corePacket->size;
}

- (void)clear
{
    _codecpar = NULL;
    _mediaType = SGMediaTypeUnknown;
    _timebase = kCMTimeZero;
    _offset = kCMTimeZero;
    _scale = CMTimeMake(1, 1);
    _timeStamp = kCMTimeZero;
    _originalTimeStamp = kCMTimeZero;
    _duration = kCMTimeZero;
    _dts = kCMTimeZero;
    _size = 0;
    if (_corePacket)
    {
        av_packet_unref(_corePacket);
    }
}

@end
