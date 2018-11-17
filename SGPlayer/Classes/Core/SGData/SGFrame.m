//
//  SGFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGFrame+Internal.h"
#import "SGTrack+Internal.h"

@interface SGFrame ()

{
    AVFrame * _frame;
    __strong SGCodecpar * _codecpar;
}

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic) NSInteger lockingCount;

@end

@implementation SGFrame

- (SGMediaType)type
{
    return SGMediaTypeUnknown;
}

- (instancetype)init
{
    if (self = [super init]) {
        _frame = av_frame_alloc();
        _codecpar = [[SGCodecpar alloc] init];
        _coreLock = [[NSLock alloc] init];
        [self clear];
    }
    return self;
}

- (void)dealloc
{
    NSAssert(_lockingCount <= 0, @"SGFrame, must be unlocked before release");
    
    [self clear];
    if (_frame) {
        av_frame_free(&_frame);
        _frame = nil;
    }
}

- (void *)coreptr {return _frame;}
- (AVFrame *)core {return _frame;}
- (SGCodecpar *)codecpar {return [_codecpar copy];}

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
    if (_frame) {
        av_frame_unref(_frame);
    }
    _timeStamp = kCMTimeZero;
    _decodeTimeStamp = kCMTimeZero;
    _duration = kCMTimeZero;
    _size = 0;
    [_codecpar clear];
}

- (void)setTimebase:(AVRational)timebase codecpar:(AVCodecParameters *)codecpar
{
    _timeStamp = CMTimeMake(_frame->best_effort_timestamp * timebase.num, timebase.den);
    _decodeTimeStamp = CMTimeMake(_frame->pkt_dts * timebase.num, timebase.den);
    _duration = CMTimeMake(_frame->pkt_duration * timebase.num, timebase.den);
    _size = _frame->pkt_size;
    [_codecpar setTimebase:timebase codecpar:codecpar];
}

- (void)setTimeLayout:(SGTimeLayout *)timeLayout
{
    if (!timeLayout) {
        return;
    }
    [_codecpar setTimeLayout:timeLayout];
    _timeStamp = [timeLayout applyToTimeStamp:_timeStamp];
    _decodeTimeStamp = [timeLayout applyToTimeStamp:_decodeTimeStamp];
    _duration = [timeLayout applyToDuration:_duration];
}

@end
