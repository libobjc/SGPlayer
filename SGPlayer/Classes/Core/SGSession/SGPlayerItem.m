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
#import "SGMixer.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGPlayerItem () <SGFrameOutputDelegate, SGObjectQueueDelegate>

{
    struct _Flags {
        BOOL isAudioFinished;
        BOOL isVudioFinished;
    } _flags;
    
    NSLock *_lock;
    NSError *_error;
    SGMixer *_audioMixer;
    SGPlayerItemState _state;
    SGObjectQueue *_audioQueue;
    SGObjectQueue *_videoQueue;
    SGFrameOutput *_frameOutput;
    SGTrack *_selectedVideoTrack;
    NSArray<SGTrack *> *_selectedAudioTracks;
    NSArray<NSNumber *> *_selectedAudioWeights;
    NSMutableDictionary<NSNumber *, SGCapacity *> *_capacitys;
}

@property (nonatomic, weak) id<SGPlayerItemDelegate> delegate;
@property (nonatomic, strong) SGFrameFilter *audioFilter;
@property (nonatomic, strong) SGFrameFilter *videoFilter;

@end

@implementation SGPlayerItem

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_audioMixer = [[SGMixer alloc] init];
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
        [self->_audioFilter destroy];
        [self->_videoFilter destroy];
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
            ret = self->_selectedAudioTracks.count > 0;
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
            ret = self->_flags.isAudioFinished;
        } else if (type == SGMediaTypeVideo) {
            ret = self->_flags.isVudioFinished;
        }
    });
    return ret;
}

- (BOOL)selectAudioTracks:(NSArray<SGTrack *> *)tracks weights:(NSArray<NSNumber *> *)weights
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return tracks.count > 0 || weights.count > 0;
    }, ^SGBlock {
        SGBlock b1 = ^{};
        if (tracks.count > 0 && ![self->_selectedAudioTracks isEqualToArray:tracks]) {
            self->_selectedAudioWeights = nil;
            self->_selectedAudioTracks = [tracks copy];
            NSMutableArray *p = [NSMutableArray arrayWithArray:self->_selectedAudioTracks];
            if (self->_selectedVideoTrack) {
                [p addObject:self->_selectedVideoTrack];
            }
            b1 = ^{
                [self->_frameOutput selectTracks:[p copy]];
            };
        }
        if (weights.count > 0 && ![self->_selectedAudioWeights isEqualToArray:weights]) {
            self->_selectedAudioWeights = [weights copy];
        }
        if (self->_selectedAudioWeights.count == 0) {
            NSMutableArray *weights = [NSMutableArray array];
            for (int i = 0; i < tracks.count; i++) {
                [weights addObject:@(100)];
            }
            self->_selectedAudioWeights = [weights copy];
        }
        return b1;
    });
}

- (NSArray<SGTrack *> *)selectedAudioTracks
{
    __block NSArray<SGTrack *> *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_selectedAudioTracks copy];
    });
    return ret;
}

- (NSArray<NSNumber *> *)selectedAudioWeights
{
    __block NSArray<NSNumber *> *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_selectedAudioWeights copy];
    });
    return ret;
}

- (BOOL)selectVideoTrack:(SGTrack *)track
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_selectedVideoTrack != track && track;
    }, ^SGBlock {
        self->_selectedVideoTrack = track;
        NSMutableArray *p = [NSMutableArray arrayWithArray:self->_selectedAudioTracks];
        if (self->_selectedVideoTrack) {
            [p addObject:self->_selectedVideoTrack];
        }
        return ^{
            [self->_frameOutput selectTracks:[p copy]];
        };
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
        [self->_audioFilter destroy];
        [self->_videoFilter destroy];
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
            [self->_audioFilter flush];
            [self->_videoFilter flush];
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
                self->_selectedAudioTracks = [audio copy];
                self->_selectedAudioWeights = [weight copy];
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

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeCapacity:(SGCapacity *)capacity track:(SGTrack *)track
{
    capacity = [capacity copy];
    __block SGCapacity *additional = nil;
    SGLockEXE00(self->_lock, ^{
        if (track.type == SGMediaTypeAudio) {
            additional = self->_audioQueue.capacity;
        } else if (track.type == SGMediaTypeVideo) {
            additional = self->_videoQueue.capacity;
        }
    });
    NSAssert(additional, @"Invalid Additional.");
    [capacity add:additional];
    [self setCapacity:capacity type:track.type];
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(SGFrame *)frame
{
    [frame lock];
    switch (frame.track.type) {
        case SGMediaTypeAudio: {
            if (self->_audioFilter) {
                frame = [self->_audioFilter convert:frame];
            }
            [self->_audioQueue putObjectSync:frame]();
        }
            break;
        case SGMediaTypeVideo: {
            if (self->_videoFilter) {
                frame = [self->_videoFilter convert:frame];
            }
            [self->_videoQueue putObjectSync:frame]();
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
    capacity = [capacity copy];
    uint32_t threshold = 0;
    SGMediaType type = SGMediaTypeUnknown;
    if (objectQueue == self->_audioQueue) {
        threshold = 5;
        type = SGMediaTypeAudio;
    } else if (objectQueue == self->_videoQueue) {
        threshold = 3;
        type = SGMediaTypeVideo;
    }
    NSMutableArray *tracks = [NSMutableArray array];
    for (SGTrack *obj in self->_frameOutput.selectedTracks) {
        if (obj.type == type) {
            [tracks addObject:obj];
        }
    }
    if (capacity.count > threshold) {
        [self->_frameOutput pause:tracks];
    } else {
        [self->_frameOutput resume:tracks];
    }
    NSArray<SGCapacity *> *capacitys = [self->_frameOutput capacityWithTrack:tracks];
    SGCapacity *additional = nil;
    for (SGCapacity *obj in capacitys) {
        additional = [obj minimum:additional];
    }
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
        NSMutableArray *audio_tracks = [NSMutableArray array];
        NSMutableArray *video_tracks = [NSMutableArray array];
        for (SGTrack *obj in self->_frameOutput.selectedTracks) {
            if (obj.type == SGMediaTypeAudio) {
                [audio_tracks addObject:obj];
            } else if (obj.type == SGMediaTypeVideo) {
                [video_tracks addObject:obj];
            }
        }
        BOOL isAudioFinished = YES;
        BOOL isVideoFinished = YES;
        NSArray *finishedTracks = self->_frameOutput.finishedTracks;
        SGCapacity *audioCapacity = [self->_capacitys objectForKey:@(SGMediaTypeAudio)];
        SGCapacity *videoCapacity = [self->_capacitys objectForKey:@(SGMediaTypeVideo)];
        for (SGTrack *obj in audio_tracks) {
            isAudioFinished = isAudioFinished && [finishedTracks containsObject:obj];
        }
        for (SGTrack *obj in video_tracks) {
            isVideoFinished = isVideoFinished && [finishedTracks containsObject:obj];
        }
        self->_flags.isAudioFinished = isAudioFinished && (!audioCapacity || audioCapacity.isEmpty);
        self->_flags.isVudioFinished = isVideoFinished && (!videoCapacity || videoCapacity.isEmpty);
        if (self->_flags.isAudioFinished && self->_flags.isVudioFinished) {
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
