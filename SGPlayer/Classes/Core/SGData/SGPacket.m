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
        _mediaType = SGMediaTypeUnknown;
        _codecpar = NULL;
        _timebase = kCMTimeZero;
        _scale = CMTimeMake(1, 1);
        _startTime = kCMTimeZero;
        _timeRange = kCMTimeRangeZero;
        _timeStamp = kCMTimeZero;
        _decodeTimeStamp = kCMTimeZero;
        _duration = kCMTimeZero;
        _originalTimeStamp = kCMTimeZero;
        _originalDecodeTimeStamp = kCMTimeZero;
        _originalDuration = kCMTimeZero;
        _size = 0;
        _keyFrame = 0;
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
    _mediaType = SGMediaTypeUnknown;
    _codecpar = NULL;
    _timebase = kCMTimeZero;
    _scale = CMTimeMake(1, 1);
    _startTime = kCMTimeZero;
    _timeRange = kCMTimeRangeZero;
    _timeStamp = kCMTimeZero;
    _decodeTimeStamp = kCMTimeZero;
    _duration = kCMTimeZero;
    _originalTimeStamp = kCMTimeZero;
    _originalDecodeTimeStamp = kCMTimeZero;
    _originalDuration = kCMTimeZero;
    _size = 0;
    _keyFrame = NO;
    if (_corePacket)
    {
        av_packet_unref(_corePacket);
    }
}

- (void)fillWithMediaType:(SGMediaType)mediaType
                 codecpar:(AVCodecParameters *)codecpar
                 timebase:(CMTime)timebase
                    scale:(CMTime)scale
                startTime:(CMTime)startTime
                timeRange:(CMTimeRange)timeRange
{
    _mediaType = mediaType;
    _codecpar = codecpar;
    _timebase = timebase;
    _scale = scale;
    _startTime = startTime;
    _timeRange = timeRange;
    _originalTimeStamp = SGCMTimeMakeWithTimebase(_corePacket->pts != AV_NOPTS_VALUE ? _corePacket->pts : _corePacket->dts, self.timebase);
    _originalDecodeTimeStamp = SGCMTimeMakeWithTimebase(_corePacket->dts, self.timebase);
    _originalDuration = SGCMTimeMakeWithTimebase(_corePacket->duration, self.timebase);
    CMTime offset = CMTimeSubtract(self.startTime, self.timeRange.start);
    _timeStamp = CMTimeAdd(offset, SGCMTimeMultiply(self.originalTimeStamp, self.scale));
    _decodeTimeStamp = CMTimeAdd(offset, SGCMTimeMultiply(self.originalDecodeTimeStamp, self.scale));
    _duration = SGCMTimeMultiply(self.originalDuration, self.scale);
    _size = _corePacket->size;
    _keyFrame = _corePacket->flags & AV_PKT_FLAG_KEY;
}

@end
