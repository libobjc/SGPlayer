//
//  SGPlayerItem.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPlayerItem.h"
#import "SGPlayerItem+Internal.h"
#import "SGAudioProcessor.h"
#import "SGObjectQueue.h"
#import "SGFrameOutput.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGPlayerItem () <SGFrameOutputDelegate>

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
        self->_capacitys = [NSMutableDictionary dictionary];
        self->_frameOutput = [[SGFrameOutput alloc] initWithAsset:asset];
        self->_frameOutput.delegate = self;
        self->_audioQueue = [[SGObjectQueue alloc] init];
        self->_videoQueue = [[SGObjectQueue alloc] init];
        self->_audioDescription = [[SGAudioDescription alloc] init];
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
        SGLockEXE00(self->_lock, ^{
            [self->_audioProcessor close];
            [self->_audioQueue destroy];
            [self->_videoQueue destroy];
        });
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
            ret = self->_audioProcessor.tracks.count > 0;
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
            NSMutableArray *m = [NSMutableArray arrayWithArray:tracks];
            if (self->_selectedVideoTrack) {
                [m addObject:self->_selectedVideoTrack];
            }
            ret = [self->_frameOutput selectTracks:[m copy]];
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
        SGLockEXE00(self->_lock, ^{
            [self->_audioProcessor close];
            [self->_audioQueue destroy];
            [self->_videoQueue destroy];
        });
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
            SGLockEXE10(self->_lock, ^SGBlock {
                [self->_audioProcessor flush];
                [self->_audioQueue flush];
                [self->_videoQueue flush];
                SGBlock b1 = [self setFrameQueueCapacity:SGMediaTypeAudio];
                SGBlock b2 = [self setFrameQueueCapacity:SGMediaTypeVideo];
                return ^{
                    b1(); b2();
                };
            });
        }
        if (result) {
            result(time, error);
        }
    }];
}

- (SGFrame *)copyAudioFrame:(SGTimeReader)timeReader
{
    __block SGFrame *ret = nil;
    SGLockEXE10(self->_lock, ^SGBlock {
        if ([self->_audioQueue getObjectAsync:&ret timeReader:timeReader]) {
            return [self setFrameQueueCapacity:SGMediaTypeAudio];
        };
        return nil;
    });
    return ret;
}

- (SGFrame *)copyVideoFrame:(SGTimeReader)timeReader
{
    __block SGFrame *ret = nil;
    SGLockEXE10(self->_lock, ^SGBlock {
        if ([self->_videoQueue getObjectAsync:&ret timeReader:timeReader]) {
            return [self setFrameQueueCapacity:SGMediaTypeVideo];
        };
        return nil;
    });
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
                for (SGTrack *obj in frameOutput.selectedTracks) {
                    if (obj.type == SGMediaTypeAudio) {
                        [audio addObject:obj];
                    } else if (obj.type == SGMediaTypeVideo) {
                        [video addObject:obj];
                    }
                }
                if (audio.count > 0) {
                    self->_audioProcessor = [[SGAudioProcessor alloc] initWithAudioDescription:self->_audioDescription];
                    [self->_audioProcessor setTracks:audio weights:nil];
                }
                if (video.count > 0) {
                    self->_selectedVideoTrack = video.firstObject;
                }
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
        case SGFrameOutputStateFinished: {
            SGLockEXE10(self->_lock, ^SGBlock {
                return [self setFinishedIfNeeded];
            });
        }
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
    SGLockEXE10(self->_lock, ^SGBlock {
        SGCapacity *additional = [self frameQueueCapacity:type];
        [capacity add:additional];
        return [self setCapacity:capacity type:type];
    });
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(__kindof SGFrame *)frame
{
    __block __kindof SGFrame *obj = frame;
    [obj lock];
    SGLockEXE10(self->_lock, ^SGBlock {
        SGMediaType type = obj.track.type;
        if (type == SGMediaTypeAudio) {
            obj = [self->_audioProcessor putFrame:obj];
            if (!obj) {
                return nil;
            }
            [self->_audioQueue putObjectSync:obj];
            return [self setFrameQueueCapacity:SGMediaTypeAudio];
        } else if (type == SGMediaTypeVideo) {
            [self->_videoQueue putObjectSync:obj];
            return [self setFrameQueueCapacity:SGMediaTypeVideo];
        }
        return nil;
    });
    [obj unlock];
}

#pragma mark - Capacity

- (SGBlock)setFrameQueueCapacity:(SGMediaType)type
{
    int threshold = 0;
    if (type == SGMediaTypeAudio) {
        threshold = 5;
    } else if (type == SGMediaTypeVideo) {
        threshold = 3;
    }
    SGCapacity *capacity = [self frameQueueCapacity:type];
    SGBlock b1 = ^{
        if (capacity.count > threshold) {
            [self->_frameOutput pause:type];
        } else {
            [self->_frameOutput resume:type];
        }
    };
    SGCapacity *additional = [self->_frameOutput capacityWithType:type];
    [additional add:additional];
    SGBlock b2 = [self setCapacity:capacity type:type];
    return ^{
        b1(); b2();
    };
}

- (SGCapacity *)frameQueueCapacity:(SGMediaType)type
{
    SGCapacity *capacity = nil;
    if (type == SGMediaTypeAudio) {
        capacity = self->_audioQueue.capacity;
        [capacity add:self->_audioProcessor.capacity];
    } else if (type == SGMediaTypeVideo) {
        capacity = self->_videoQueue.capacity;
    }
    return capacity;
}

- (SGBlock)setCapacity:(SGCapacity *)capacity type:(SGMediaType)type
{
    SGCapacity *obj = [self->_capacitys objectForKey:@(type)];
    if ([obj isEqualToCapacity:capacity]) {
        return ^{};
    }
    [self->_capacitys setObject:capacity forKey:@(type)];
    SGBlock b1 = ^{
        [self->_delegate playerItem:self didChangeCapacity:[capacity copy] type:type];
    };
    SGBlock b2 = [self setFinishedIfNeeded];
    return ^{
        b1(); b2();
    };
}

- (SGBlock)setFinishedIfNeeded
{
    BOOL nomore = self->_frameOutput.state == SGFrameOutputStateFinished;
    SGCapacity *audioCapacity = [self->_capacitys objectForKey:@(SGMediaTypeAudio)];
    SGCapacity *videoCapacity = [self->_capacitys objectForKey:@(SGMediaTypeVideo)];
    self->_audioFinished = nomore && (!audioCapacity || audioCapacity.isEmpty);
    self->_videoFinished = nomore && (!videoCapacity || videoCapacity.isEmpty);
    if (self->_audioFinished && self->_videoFinished) {
        return [self setState:SGPlayerItemStateFinished];
    }
    return ^{};
}

@end
