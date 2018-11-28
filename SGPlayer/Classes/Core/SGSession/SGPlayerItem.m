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
#import "SGAudioProcessor.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGPlayerItem () <SGFrameOutputDelegate, SGObjectQueueDelegate>

{
    NSLock *_lock;
    SGObjectQueue *_audioQueue;
    SGObjectQueue *_videoQueue;
    SGFrameOutput *_frameOutput;
    SGAudioProcessor *_audioProcessor;
    NSMutableDictionary<NSNumber *, SGCapacity *> *_capacitys;
    
    NSError *_error;
    SGPlayerItemState _state;
    SGTrack *_selectedVideoTrack;
    
    BOOL _audioFinished;
    BOOL _videoFinished;
}

@end

@implementation SGPlayerItem

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_audioProcessor = [[SGAudioProcessor alloc] init];
        self->_capacitys = [NSMutableDictionary dictionary];
        self->_frameOutput = [[SGFrameOutput alloc] initWithAsset:asset];
        self->_frameOutput.delegate = self;
        self->_audioQueue = [[SGObjectQueue alloc] init];
        self->_audioQueue.delegate = self;
        self->_videoQueue = [[SGObjectQueue alloc] init];
        self->_videoQueue.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_state != SGPlayerItemStateClosed;
    }, ^SGBlock {
        [self setState:SGPlayerItemStateClosed];
        [self->_frameOutput close];
        [self->_audioQueue destroy];
        [self->_videoQueue destroy];
        return nil;
    });
}

#pragma mark - Mapping

SGGet0Map(CMTime, duration, self->_frameOutput)
SGGet0Map(NSDictionary *, metadata, self->_frameOutput)
SGGet0Map(NSArray<SGTrack *> *, tracks, self->_frameOutput)

#pragma mark - Setter & Getter

- (NSError *)error
{
    __block NSError *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_error copy];
    });
    return ret;
}

- (SGBlock)setState:(SGPlayerItemState)state
{
    if (_state == state) {
        return ^{};
    }
    _state = state;
    return ^{
        [self->_delegate playerItem:self didChangeState:state];
    };
}

- (SGPlayerItemState)state
{
    __block SGPlayerItemState ret = SGPlayerItemStateNone;
    SGLockEXE00(self->_lock, ^{
        ret = self->_state;
    });
    return ret;
}

- (SGCapacity *)capacityWithType:(SGMediaType)type
{
    __block SGCapacity *ret = nil;
    SGLockEXE00(self->_lock, ^{
         ret = [[self->_capacitys objectForKey:@(type)] copy];
    });
    return ret ? ret : [[SGCapacity alloc] init];
}

- (BOOL)isAvailable:(SGMediaType)type
{
    __block BOOL ret = NO;
    SGLockEXE00(self->_lock, ^{
        if (type == SGMediaTypeAudio) {
            ret = self->_audioProcessor.isAvailable;
        } else if (type == SGMediaTypeVideo) {
            ret = self->_selectedVideoTrack != nil;
        }
    });
    return ret;
}

- (BOOL)isFinished:(SGMediaType)type
{
    __block BOOL ret = NO;
    SGLockEXE00(self->_lock, ^{
        if (type == SGMediaTypeAudio) {
            ret = self->_audioFinished;
        } else if (type == SGMediaTypeVideo) {
            ret = self->_videoFinished;
        }
    });
    return ret;
}

- (BOOL)selectAudioTracks:(NSArray<SGTrack *> *)tracks weights:(NSArray<NSNumber *> *)weights
{
    __block BOOL ret = YES;
    SGLockCondEXE10(self->_lock, ^BOOL {
        return tracks != 0 || weights != 0;
    }, ^SGBlock {
        if (tracks.count > 0) {
            NSArray *p = tracks;
            if (self->_selectedVideoTrack) {
                NSMutableArray *m = [NSMutableArray arrayWithArray:tracks];
                [m addObject:self->_selectedVideoTrack];
            }
            ret = [self->_frameOutput selectTracks:[p copy]];
        }
        if (ret) {
            ret = [self->_audioProcessor setTracks:tracks weights:weights];
        }
        return nil;
    });
    return ret;
}

- (NSArray<SGTrack *> *)selectedAudioTracks
{
    __block NSArray *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_audioProcessor.tracks copy];
    });
    return ret;
}

- (NSArray<NSNumber *> *)selectedAudioWeights
{
    __block NSArray *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_audioProcessor.weights copy];
    });
    return ret;
}

- (BOOL)selectVideoTrack:(SGTrack *)track
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_selectedVideoTrack != track && track;
    }, ^SGBlock {
        self->_selectedVideoTrack = track;
        NSMutableArray *p = [NSMutableArray arrayWithArray:self->_audioProcessor.tracks];
        [p addObject:self->_selectedVideoTrack];
        [self->_frameOutput selectTracks:[p copy]];
        return nil;
    });
}

- (SGTrack *)selectedVideoTrack
{
    __block SGTrack *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = self->_selectedVideoTrack;
    });
    return ret;
}

#pragma mark - Control

- (BOOL)open
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state == SGPlayerItemStateNone;
    }, ^SGBlock {
        return [self setState:SGPlayerItemStateOpening];
    }, ^BOOL(SGBlock block) {
        block();
        return [self->_frameOutput open];
    });
}

- (BOOL)start
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state == SGPlayerItemStateOpened;
    }, ^SGBlock {
        return [self setState:SGPlayerItemStateReading];;
    }, ^BOOL(SGBlock block) {
        block();
        return [self->_frameOutput start];
    });
}

- (BOOL)close
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state != SGPlayerItemStateClosed;
    }, ^SGBlock {
        return [self setState:SGPlayerItemStateClosed];
    }, ^BOOL(SGBlock block) {
        block();
        [self->_frameOutput close];
        [self->_audioProcessor close];
        [self->_audioQueue destroy];
        [self->_videoQueue destroy];
        return YES;
    });
}

- (BOOL)seekable
{
    return self->_frameOutput.seekable;
}

- (BOOL)seekToTime:(CMTime)time result:(SGSeekResult)result
{
    SGWeakify(self)
    return ![self->_frameOutput seekToTime:time result:^(CMTime time, NSError *error) {
        SGStrongify(self)
        if (!error) {
            [self->_audioProcessor flush];
            SGBlock b1 = [self->_audioQueue flush];
            SGBlock b2 = [self->_videoQueue flush];
            b1(); b2();
        }
        if (result) {
            result(time, error);
        }
    }];
}

- (SGFrame *)copyAudioFrame:(SGTimeReader)timeReader
{
    SGFrame *ret = nil;
    [self->_audioQueue getObjectAsync:&ret timeReader:timeReader]();
    return ret;
}

- (SGFrame *)copyVideoFrame:(SGTimeReader)timeReader
{
    SGFrame *ret = nil;
    [self->_videoQueue getObjectAsync:&ret timeReader:timeReader]();
    return ret;
}

#pragma mark - SGFrameOutputDelegate

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeState:(SGFrameOutputState)state
{
    switch (state) {
        case SGFrameOutputStateOpened: {
            SGLockEXE10(self->_lock, ^SGBlock {
                NSMutableArray *video = [NSMutableArray array];
                NSMutableArray *audio = [NSMutableArray array];
                NSMutableArray *weight = [NSMutableArray array];
                for (SGTrack *obj in frameOutput.selectedTracks) {
                    if (obj.type == SGMediaTypeAudio) {
                        [audio addObject:obj];
                        [weight addObject:@(100)];
                    } else if (obj.type == SGMediaTypeVideo) {
                        [video addObject:obj];
                    }
                }
                self->_selectedVideoTrack = video.firstObject;
                [self->_audioProcessor setAudioDescription:self->_audioDescription];
                [self->_audioProcessor setTracks:audio weights:weight];
                return [self setState:SGPlayerItemStateOpened];
            });
        }
            break;
        case SGFrameOutputStateReading: {
            SGLockEXE10(self->_lock, ^SGBlock {
                return [self setState:SGPlayerItemStateReading];
            });
        }
            break;
        case SGFrameOutputStateSeeking: {
            SGLockEXE10(self->_lock, ^SGBlock {
                return [self setState:SGPlayerItemStateSeeking];
            });
        }
            break;
        case SGFrameOutputStateFinished:
            break;
        case SGFrameOutputStateFailed: {
            SGLockEXE10(self->_lock, ^SGBlock {
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
    __block SGCapacity *additional = nil;
    SGLockEXE00(self->_lock, ^{
        if (type == SGMediaTypeAudio) {
            additional = self->_audioQueue.capacity;
        } else if (type == SGMediaTypeVideo) {
            additional = self->_videoQueue.capacity;
        }
    });
    NSAssert(additional, @"Invalid Additional.");
    [capacity add:additional];
    [self setCapacity:capacity type:type];
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(__kindof SGFrame *)frame
{
    __block __kindof SGFrame *obj = frame;
    [obj lock];
    SGLockEXE10(self->_lock, ^SGBlock{
        if (obj.track.type == SGMediaTypeAudio) {
            obj = [self->_audioProcessor putFrame:obj];
            if (!obj) {
                return nil;
            }
            return [self->_audioQueue putObjectSync:obj];
        } else if (obj.track.type == SGMediaTypeVideo) {
            return [self->_videoQueue putObjectSync:obj];
        }
        return nil;
    });
    [obj unlock];
}

#pragma mark - SGObjectQueueDelegate

- (void)objectQueue:(SGObjectQueue *)objectQueue didChangeCapacity:(SGCapacity *)capacity
{
    capacity = [capacity copy];
    int threshold = 0;
    SGMediaType type = SGMediaTypeUnknown;
    if (objectQueue == self->_audioQueue) {
        threshold = 5;
        type = SGMediaTypeAudio;
    } else if (objectQueue == self->_videoQueue) {
        threshold = 3;
        type = SGMediaTypeVideo;
    }
    if (capacity.count > threshold) {
        [self->_frameOutput pause:type];
    } else {
        [self->_frameOutput resume:type];
    }
    SGCapacity *additional = [self->_frameOutput capacityWithType:type];
    [capacity add:additional];
    [self setCapacity:capacity type:type];
}

#pragma mark - Capacity

- (BOOL)setCapacity:(SGCapacity *)capacity type:(SGMediaType)type
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        SGCapacity *last = [self->_capacitys objectForKey:@(type)];
        return ![last isEqualToCapacity:capacity];
    }, ^SGBlock {
        [self->_capacitys setObject:capacity forKey:@(type)];
        SGCapacity *audioMixerCapacity = [self->_audioProcessor capacity];
        SGCapacity *audioCapacity = [self->_capacitys objectForKey:@(SGMediaTypeAudio)];
        SGCapacity *videoCapacity = [self->_capacitys objectForKey:@(SGMediaTypeVideo)];
        BOOL finished = self->_frameOutput.state == SGFrameOutputStateFinished;
        self->_audioFinished = finished && (!audioCapacity || audioCapacity.isEmpty) && (!audioMixerCapacity || audioMixerCapacity.isEmpty);
        self->_videoFinished = finished && (!videoCapacity || videoCapacity.isEmpty);
        if (self->_audioFinished && self->_videoFinished) {
            return [self setState:SGPlayerItemStateFinished];
        }
        return nil;
    }, ^BOOL(SGBlock block) {
        [self->_delegate playerItem:self didChangeCapacity:[capacity copy] type:type];
        block();
        return YES;
    });
}

@end
