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

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic) NSInteger lockingCount;

@property (nonatomic) AVFrame * core;
@property (nonatomic) void * core_ptr;
@property (nonatomic) AVRational timebase;
@property (nonatomic) NSMutableArray <SGTimeTransform *> * timeTransforms;

@end

@implementation SGFrame

- (instancetype)init
{
    if (self = [super init])
    {
        self.coreLock = [[NSLock alloc] init];
        self.core = av_frame_alloc();
        self.core_ptr = self.core;
        [self clear];
    }
    return self;
}

- (void)dealloc
{
    NSAssert(self.lockingCount <= 0, @"SGFrame, must be unlocked before release");
    
    [self clear];
    if (self.core) {
        av_frame_free(&_core);
        _core = NULL;
    }
    self.core_ptr = nil;
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
    if (self.lockingCount <= 0) {
        self.lockingCount = 0;
        [[SGObjectPool sharePool] comeback:self];
    }
}

- (void)clear
{
    if (self.core) {
        av_frame_unref(self.core);
    }
    _type = SGMediaTypeUnknown;
    _index = -1;
    _timeStamp = kCMTimeZero;
    _decodeTimeStamp = kCMTimeZero;
    _duration = kCMTimeZero;
    _size = 0;
    _timebase = av_make_q(0, 1);
    [_timeTransforms removeAllObjects];
}

- (void)configurateWithType:(SGMediaType)type timebase:(AVRational)timebase index:(int32_t)index
{
    _type = type;
    _index = index;
    _timeStamp = CMTimeMake(self.core->best_effort_timestamp * timebase.num, timebase.den);
    _decodeTimeStamp = CMTimeMake(self.core->pkt_dts * timebase.num, timebase.den);
    _duration = CMTimeMake(self.core->pkt_duration * timebase.num, timebase.den);
    _size = self.core->pkt_size;
    _timebase = timebase;
}

- (void)applyTimeTransforms:(NSArray <SGTimeTransform *> *)timeTransforms
{
    for (SGTimeTransform * obj in timeTransforms) {
        [self applyTimeTransform:obj];
    }
}

- (void)applyTimeTransform:(SGTimeTransform *)timeTransform
{
    if (!timeTransform) {
        return;
    }
    if (!_timeTransforms) {
        _timeTransforms = [NSMutableArray array];
    }
    [self.timeTransforms addObject:timeTransform];
    _timeStamp = [timeTransform applyToTimeStamp:_timeStamp];
    _decodeTimeStamp = [timeTransform applyToTimeStamp:_decodeTimeStamp];
    _duration = [timeTransform applyToDuration:_duration];
}

@end
