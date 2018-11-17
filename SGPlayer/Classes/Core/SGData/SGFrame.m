//
//  SGFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGFrame+Internal.h"

@interface SGFrame ()

{
    AVFrame * _frame;
    AVRational _timebase;
    NSMutableArray * _timeLayouts;
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
        _coreLock = [[NSLock alloc] init];
        _timeLayouts = [NSMutableArray array];
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
    _timebase = av_make_q(0, 1);
    [_timeLayouts removeAllObjects];
}

- (void)setTimebase:(AVRational)timebase
{
    _timeStamp = CMTimeMake(_frame->best_effort_timestamp * timebase.num, timebase.den);
    _decodeTimeStamp = CMTimeMake(_frame->pkt_dts * timebase.num, timebase.den);
    _duration = CMTimeMake(_frame->pkt_duration * timebase.num, timebase.den);
    _size = _frame->pkt_size;
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

- (void)setFrame:(SGFrame *)frame
{
    [self setTimebase:frame->_timebase];
    for (SGTimeLayout * obj in frame->_timeLayouts) {
        [self setTimeLayout:obj];
    }
}

@end
