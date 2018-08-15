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
        _timebase = av_make_q(0, 1);
        _offset = kCMTimeZero;
        _scale = CMTimeMake(1, 1);
        _timeStamp = kCMTimeZero;
        _duration = kCMTimeZero;
        _originalTimeStamp = kCMTimeZero;
        _originalTimeStamp = kCMTimeZero;
        _decodeTimeStamp = kCMTimeZero;
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
    AVRational defaultTimebase = stream.mediaType == SGMediaTypeAudio ? av_make_q(1, 44100) : av_make_q(1, 25000);
    _timebase = SGRationalValidate(stream.timebase, defaultTimebase);
    _codecpar = stream.coreStream->codecpar;
    _mediaType = stream.mediaType;
    _offset = offset;
    _scale = scale;
    _originalTimeStamp = SGCMTimeMakeWithRational(_corePacket->pts != AV_NOPTS_VALUE ? _corePacket->pts : _corePacket->dts, self.timebase);
    _originalDuration = SGCMTimeMakeWithRational(_corePacket->duration, self.timebase);
    _timeStamp = CMTimeAdd(self.offset, SGCMTimeMultiply(self.originalTimeStamp, self.scale));
    _duration = SGCMTimeMultiply(self.originalDuration, self.scale);
    _decodeTimeStamp = SGCMTimeMakeWithRational(_corePacket->dts, self.timebase);
    _size = _corePacket->size;
}

- (void)clear
{
    _codecpar = NULL;
    _mediaType = SGMediaTypeUnknown;
    _timebase = av_make_q(0, 1);
    _offset = kCMTimeZero;
    _scale = CMTimeMake(1, 1);
    _timeStamp = kCMTimeZero;
    _duration = kCMTimeZero;
    _originalTimeStamp = kCMTimeZero;
    _originalDuration = kCMTimeZero;
    _decodeTimeStamp = kCMTimeZero;
    _size = 0;
    if (_corePacket)
    {
        av_packet_unref(_corePacket);
    }
}

@end
