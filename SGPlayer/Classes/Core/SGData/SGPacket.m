//
//  SGPacket.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPacket.h"
#import "SGPacket+Internal.h"

@interface SGPacket ()

{
    AVPacket * _packet;
    AVRational _timebase;
    Class _decodeableClass;
    NSMutableArray * _timeLayouts;
    AVCodecParameters * _codecpar;
}

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic) NSInteger lockingCount;

@end

@implementation SGPacket

- (instancetype)init
{
    if (self = [super init]) {
        _packet = av_packet_alloc();
        _coreLock = [[NSLock alloc] init];
        _timeLayouts = [NSMutableArray array];
        [self clear];
    }
    return self;
}

- (void)dealloc
{
    NSAssert(_lockingCount <= 0, @"SGPacket, must be unlocked before release");
    
    [self clear];
    if (_packet) {
        av_packet_free(&_packet);
        _packet = nil;
    }
}

- (void *)coreptr {return _packet;}
- (AVPacket *)core {return _packet;}

- (void)lock
{
    [_coreLock lock];
    _lockingCount++;
    [_coreLock unlock];
}

- (void)unlock
{
    [_coreLock lock];
    _lockingCount--;
    [_coreLock unlock];
    if (_lockingCount <= 0) {
        _lockingCount = 0;
        [[SGObjectPool sharePool] comeback:self];
    }
}

- (void)clear
{
    if (_packet) {
        av_packet_unref(_packet);
    }
    _index = -1;
    _timeStamp = kCMTimeZero;
    _decodeTimeStamp = kCMTimeZero;
    _duration = kCMTimeZero;
    _size = 0;
    _timebase = av_make_q(0, 1);
    _codecpar = nil;
    _decodeableClass = nil;
    [_timeLayouts removeAllObjects];
}

- (void)setTimebase:(AVRational)timebase codecpar:(AVCodecParameters *)codecpar
{
    if (_packet->pts == AV_NOPTS_VALUE) {
        _packet->pts = _packet->dts;
    }
    _index = _packet->stream_index;
    _timeStamp = CMTimeMake(_packet->pts * timebase.num, timebase.den);
    _decodeTimeStamp = CMTimeMake(_packet->dts * timebase.num, timebase.den);
    _duration = CMTimeMake(_packet->duration * timebase.num, timebase.den);
    _size = _packet->size;
    _timebase = timebase;
    _codecpar = codecpar;
}

- (void)setTimeLayout:(SGTimeLayout *)timeLayout
{
    if (!timeLayout) {
        return;
    }
    [_timeLayouts addObject:timeLayout];
    _timeStamp = [timeLayout applyToTimeStamp:_timeStamp];
    _decodeTimeStamp = [timeLayout applyToTimeStamp:_decodeTimeStamp];
    _duration = [timeLayout applyToDuration:_duration];
}

- (void)setDecodeableClass:(Class)decodeableClass
{
    _decodeableClass = decodeableClass;
}

- (void)setIndex:(uint32_t)index
{
    _index = index;
}

- (SGCodecDescription *)codecDescription
{
    SGCodecDescription * ret = [[SGCodecDescription alloc] init];
    ret.timebase = self->_timebase;
    ret.codecpar = self->_codecpar;
    ret.decodeableClass = self->_decodeableClass;
    ret.timeLayouts = self->_timeLayouts;
    return ret;
}

@end
