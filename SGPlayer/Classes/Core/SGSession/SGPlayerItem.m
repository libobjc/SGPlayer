//
//  SGPlayerItem.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPlayerItem.h"
#import "SGPlayerItem+Internal.h"
#import "SGFrameOutput.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGPlayerItem () <SGFrameOutputDelegate, SGObjectQueueDelegate>

{
    SGPlayerItemState _state;
    int32_t _is_audio_finished;
    int32_t _is_video_finished;
    __strong NSError * _error;
}

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) SGFrameOutput * frameOutput;
@property (nonatomic, strong) SGObjectQueue * audioQueue;
@property (nonatomic, strong) SGObjectQueue * videoQueue;
@property (nonatomic, strong) NSMutableDictionary * capacitys;

@property (nonatomic, weak) id <SGPlayerItemDelegate> delegate;
@property (nonatomic, strong) SGFrameFilter * audioFilter;
@property (nonatomic, strong) SGFrameFilter * videoFilter;

@end

@implementation SGPlayerItem

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self.lock = [[NSLock alloc] init];
        self.capacitys = [NSMutableDictionary dictionary];
        self.frameOutput = [[SGFrameOutput alloc] initWithAsset:asset];
        self.frameOutput.delegate = self;
        self.audioQueue = [[SGObjectQueue alloc] init];
        self.audioQueue.delegate = self;
        self.videoQueue = [[SGObjectQueue alloc] init];
        self.videoQueue.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    SGLockCondEXE10(self.lock, ^BOOL {
        return self->_state != SGPlayerItemStateClosed;
    }, ^SGBlock {
        [self setState:SGPlayerItemStateClosed];
        [self.frameOutput close];
        [self.audioFilter destroy];
        [self.videoFilter destroy];
        [self.audioQueue destroy];
        [self.videoQueue destroy];
        return nil;
    });
}

#pragma mark - Mapping

SGGet0Map(CMTime, duration, self.frameOutput)
SGGet0Map(NSDictionary *, metadata, self.frameOutput)
SGGet0Map(NSArray <SGTrack *> *, tracks, self.frameOutput)
SGSet1Map(void, setSelectedAudioTrack, SGTrack *, self.frameOutput)
SGGet0Map(SGTrack *, selectedAudioTrack, self.frameOutput)
SGSet1Map(void, setSelectedVideoTrack, SGTrack *, self.frameOutput)
SGGet0Map(SGTrack *, selectedVideoTrack, self.frameOutput)
SGGet0Map(BOOL, isAudioAvailable, self.frameOutput)
SGGet0Map(BOOL, isVideoAvailable, self.frameOutput)

#pragma mark - Setter & Getter

- (SGBlock)setState:(SGPlayerItemState)state
{
    if (_state == state) {
        return ^{};
    }
    _state = state;
    return ^{
        [self.delegate playerItem:self didChangeState:state];
    };
}

- (SGPlayerItemState)state
{
    __block SGPlayerItemState ret = SGPlayerItemStateNone;
    SGLockEXE00(self.lock, ^{
        ret = self->_state;
    });
    return ret;
}

- (NSError *)error
{
    __block NSError * ret = nil;
    SGLockEXE00(self.lock, ^{
        ret = [self->_error copy];
    });
    return ret;
}

- (SGCapacity *)capacity
{
    __block SGCapacity * ret = nil;
    SGLockEXE00(self.lock, ^{
        SGMediaType type = SGMediaTypeUnknown;
        if (self.frameOutput.isAudioAvailable) {
            type = SGMediaTypeAudio;
        } else if (self.frameOutput.isVideoAvailable) {
            type = SGMediaTypeVideo;
        }
        ret = [[self.capacitys objectForKey:@(type)] copy];
    });
    return ret ? ret : [[SGCapacity alloc] init];
}

- (SGCapacity *)capacityWithType:(SGMediaType)type
{
    __block SGCapacity * ret = nil;
    SGLockEXE00(self.lock, ^{
         ret = [[self.capacitys objectForKey:@(type)] copy];
    });
    return ret ? ret : [[SGCapacity alloc] init];
}

- (BOOL)isAudioFinished
{
    __block BOOL ret = NO;
    SGLockEXE00(self.lock, ^{
        ret = self->_is_audio_finished;
    });
    return ret;
}

- (BOOL)isVideoFinished
{
    __block BOOL ret = NO;
    SGLockEXE00(self.lock, ^{
        ret = self->_is_video_finished;
    });
    return ret;
}

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state == SGPlayerItemStateNone;
    }, ^SGBlock {
        return [self setState:SGPlayerItemStateOpening];
    }, ^BOOL(SGBlock block) {
        block();
        return [self.frameOutput open];
    });
}

- (BOOL)start
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state == SGPlayerItemStateOpened;
    }, ^SGBlock {
        return [self setState:SGPlayerItemStateReading];;
    }, ^BOOL(SGBlock block) {
        block();
        return [self.frameOutput start];
    });
}

- (BOOL)close
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state != SGPlayerItemStateClosed;
    }, ^SGBlock {
        return [self setState:SGPlayerItemStateClosed];
    }, ^BOOL(SGBlock block) {
        block();
        [self.frameOutput close];
        [self.audioFilter destroy];
        [self.videoFilter destroy];
        [self.audioQueue destroy];
        [self.videoQueue destroy];
        return YES;
    });
}

#pragma mark - Seek

- (BOOL)seekable
{
    return self.frameOutput.seekable;
}

- (BOOL)seekToTime:(CMTime)time result:(SGSeekResultBlock)result
{
    SGWeakify(self)
    return ![self.frameOutput seekToTime:time result:^(CMTime time, NSError * error) {
        SGStrongify(self)
        if (!error) {
            [self.audioFilter flush];
            [self.videoFilter flush];
            SGBlock b1 = [self.audioQueue flush];
            SGBlock b2 = [self.videoQueue flush];
            b1(); b2();
        }
        if (result) {
            result(time, error);
        }
    }];
}

- (SGFrame *)copyAudioFrame:(SGTimeReaderBlock)timeReader
{
    SGFrame * ret = nil;
    [self.audioQueue getObjectAsync:&ret timeReader:timeReader]();
    return ret;
}

- (SGFrame *)copyVideoFrame:(SGTimeReaderBlock)timeReader
{
    SGFrame * ret = nil;
    [self.videoQueue getObjectAsync:&ret timeReader:timeReader]();
    return ret;
}

#pragma mark - SGFrameOutputDelegate

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeState:(SGFrameOutputState)state
{
    switch (state) {
        case SGFrameOutputStateOpened: {
            SGLockEXE10(self.lock, ^SGBlock {
                return [self setState:SGPlayerItemStateOpened];
            });
        }
            break;
        case SGFrameOutputStateReading: {
            SGLockEXE10(self.lock, ^SGBlock {
                return [self setState:SGPlayerItemStateReading];
            });
        }
            break;
        case SGFrameOutputStateSeeking: {
            SGLockEXE10(self.lock, ^SGBlock {
                return [self setState:SGPlayerItemStateSeeking];
            });
        }
            break;
        case SGFrameOutputStateFinished:
            break;
        case SGFrameOutputStateFailed: {
            SGLockEXE10(self.lock, ^SGBlock {
                self->_error = [frameOutput.error copy];
                return [self setState:SGPlayerItemStateFailed];
            });
        }
            break;
        default:
            break;
    }
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeCapacity:(SGCapacity *)capacity type:(SGMediaType)type
{
    capacity = [capacity copy];
    __block SGCapacity * additional = nil;
    SGLockEXE00(self.lock, ^{
        if (type == SGMediaTypeAudio) {
            additional = self.audioQueue.capacity;
        } else if (type == SGMediaTypeVideo) {
            additional = self.videoQueue.capacity;
        }
    });
    NSAssert(additional, @"Invalid additional.");
    [capacity add:additional];
    [self setCapacity:capacity type:type];
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(SGFrame *)frame
{
    [frame lock];
    switch (frame.type) {
        case SGMediaTypeAudio: {
            if (self.audioFilter) {
                frame = [self.audioFilter convert:frame];
            }
            [self.audioQueue putObjectSync:frame]();
        }
            break;
        case SGMediaTypeVideo: {
            if (self.videoFilter) {
                frame = [self.videoFilter convert:frame];
            }
            [self.videoQueue putObjectSync:frame]();
        }
            break;
        default:
            break;
    }
    [frame unlock];
}

#pragma mark - SGObjectQueueDelegate

- (void)objectQueue:(SGObjectQueue *)objectQueue didChangeCapacity:(SGCapacity *)capacity
{
    uint32_t threshold = 0;
    SGMediaType type = SGMediaTypeUnknown;
    if (objectQueue == self.audioQueue) {
        threshold = 5;
        type = SGMediaTypeAudio;
    } else if (objectQueue == self.videoQueue) {
        threshold = 3;
        type = SGMediaTypeVideo;
    }
    capacity = [capacity copy];
    if (capacity.count > threshold) {
        [self.frameOutput pause:type];
    } else {
        [self.frameOutput resume:type];
    }
    SGCapacity * additional = [self.frameOutput capacityWithType:type];
    [capacity add:additional];
    [self setCapacity:capacity type:type];
}

#pragma mark - Capacity

- (BOOL)setCapacity:(SGCapacity *)capacity type:(SGMediaType)type
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        SGCapacity * last = [self.capacitys objectForKey:@(type)];
        return ![last isEqualToCapacity:capacity];
    }, ^SGBlock {
        [self.capacitys setObject:capacity forKey:@(type)];
        SGCapacity * audio = [self.capacitys objectForKey:@(SGMediaTypeAudio)];
        SGCapacity * video = [self.capacitys objectForKey:@(SGMediaTypeVideo)];
        self->_is_audio_finished = (!audio || audio.isEmpty) && self.frameOutput.isAudioFinished;
        self->_is_video_finished = (!video || video.isEmpty) && self.frameOutput.isVideoFinished;
        if ((!self.frameOutput.isAudioAvailable || self->_is_audio_finished) &&
            (!self.frameOutput.isVideoAvailable || self->_is_video_finished)) {
            return [self setState:SGPlayerItemStateFinished];
        }
        return nil;
    }, ^BOOL(SGBlock block) {
        [self.delegate playerItem:self didChangeCapacity:[capacity copy] type:type];
        block();
        return YES;
    });
}

@end
