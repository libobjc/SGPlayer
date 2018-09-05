//
//  SGPacket.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPacket.h"

@interface SGPacket ()

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, assign) NSInteger lockingCount;

@end

@implementation SGPacket

- (instancetype)init
{
    if (self = [super init])
    {
        self.coreLock = [[NSLock alloc] init];
        _corePacket = av_packet_alloc();
        _codecpar = NULL;
        _mediaType = SGMediaTypeUnknown;
        _timebase = kCMTimeZero;
        _offset = kCMTimeZero;
        _scale = CMTimeMake(1, 1);
        _timeStamp = kCMTimeZero;
        _decodeTimeStamp = kCMTimeZero;
        _duration = kCMTimeZero;
        _originalTimeStamp = kCMTimeZero;
        _originalDecodeTimeStamp = kCMTimeZero;
        _originalDuration = kCMTimeZero;
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
    NSAssert(self.lockingCount <= 0, @"SGPacket, must be unlocked before release");
}

- (void)lock
{
    [self.coreLock lock];
    self.lockingCount++;
    [self.coreLock unlock];
}

- (void)unlock
{
    [self.coreLock lock];
    self.lockingCount--;
    [self.coreLock unlock];
    if (self.lockingCount <= 0)
    {
        self.lockingCount = 0;
        [[SGObjectPool sharePool] comeback:self];
    }
}

- (void)clear
{
    _codecpar = NULL;
    _mediaType = SGMediaTypeUnknown;
    _timebase = kCMTimeZero;
    _offset = kCMTimeZero;
    _scale = CMTimeMake(1, 1);
    _timeStamp = kCMTimeZero;
    _decodeTimeStamp = kCMTimeZero;
    _duration = kCMTimeZero;
    _originalTimeStamp = kCMTimeZero;
    _originalDecodeTimeStamp = kCMTimeZero;
    _originalDuration = kCMTimeZero;
    _size = 0;
    if (_corePacket)
    {
        av_packet_unref(_corePacket);
    }
}

- (void)fillWithStream:(SGStream *)stream
{
    [self fillWithStream:stream offset:kCMTimeZero scale:CMTimeMake(1, 1)];
}

- (void)fillWithStream:(SGStream *)stream offset:(CMTime)offset scale:(CMTime)scale
{
    CMTime defaultTimebase = stream.mediaType == SGMediaTypeAudio ? CMTimeMake(1, 44100) : CMTimeMake(1, 25000);
    _timebase = SGCMTimeValidate(stream.timebase, defaultTimebase);
    _codecpar = stream.coreStream->codecpar;
    _mediaType = stream.mediaType;
    _offset = offset;
    _scale = scale;
    _originalTimeStamp = SGCMTimeMakeWithTimebase(_corePacket->pts != AV_NOPTS_VALUE ? _corePacket->pts : _corePacket->dts, self.timebase);
    _originalDecodeTimeStamp = SGCMTimeMakeWithTimebase(_corePacket->dts, self.timebase);
    _originalDuration = SGCMTimeMakeWithTimebase(_corePacket->duration, self.timebase);
    _timeStamp = CMTimeAdd(self.offset, SGCMTimeMultiply(self.originalTimeStamp, self.scale));
    _decodeTimeStamp = CMTimeAdd(self.offset, SGCMTimeMultiply(self.originalDecodeTimeStamp, self.scale));
    _duration = SGCMTimeMultiply(self.originalDuration, self.scale);
    _size = _corePacket->size;
}

@end
