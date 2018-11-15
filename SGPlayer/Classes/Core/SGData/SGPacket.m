//
//  SGPacket.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPacket.h"
#import "SGPacket+Internal.h"
#import "SGTrack+Internal.h"

@interface SGPacket ()

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic) NSInteger lockingCount;

@property (nonatomic) AVPacket * core;
@property (nonatomic) void * core_ptr;
@property (nonatomic) void * codecpar_ptr;
@property (nonatomic) AVRational timebase;
@property (nonatomic) AVCodecParameters * codecpar;
@property (nonatomic) NSMutableArray <SGTimeTransform *> * timeTransforms;

@end

@implementation SGPacket

- (instancetype)init
{
    if (self = [super init]) {
        self.coreLock = [[NSLock alloc] init];
        self.core = av_packet_alloc();
        self.core_ptr = self.core;
        [self clear];
    }
    return self;
}

- (void)dealloc
{
    NSAssert(self.lockingCount <= 0, @"SGPacket, must be unlocked before release");
    
    [self clear];
    if (self.core) {
        av_packet_free(&_core);
        self.core = nil;
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
        av_packet_unref(self.core);
    }
    _type = SGMediaTypeUnknown;
    _index = -1;
    _timeStamp = kCMTimeZero;
    _decodeTimeStamp = kCMTimeZero;
    _duration = kCMTimeZero;
    _size = 0;
    _timebase = av_make_q(0, 1);
    _codecpar = nil;
    _codecpar_ptr = nil;
    [_timeTransforms removeAllObjects];
}

- (void)configurateWithType:(SGMediaType)type timebase:(AVRational)timebase codecpar:(AVCodecParameters *)codecpar
{
    if (self.core->pts == AV_NOPTS_VALUE) {
        self.core->pts = self.core->dts;
    }
    _type = type;
    _index = self.core->stream_index;
    _timeStamp = CMTimeMake(self.core->pts * timebase.num, timebase.den);
    _decodeTimeStamp = CMTimeMake(self.core->dts * timebase.num, timebase.den);
    _duration = CMTimeMake(self.core->duration * timebase.num, timebase.den);
    _size = self.core->size;
    _timebase = timebase;
    _codecpar = codecpar;
    _codecpar_ptr = codecpar;
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
    [_timeTransforms addObject:timeTransform];
    _timeStamp = [timeTransform applyToTimeStamp:_timeStamp];
    _decodeTimeStamp = [timeTransform applyToTimeStamp:_decodeTimeStamp];
    _duration = [timeTransform applyToDuration:_duration];
}

@end
