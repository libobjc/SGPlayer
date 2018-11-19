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
    NSLock * _lock;
    NSError * _error;
    SGFrameOutput * _output;
    SGPlayerItemState _state;
    int32_t _is_audio_finished;
    int32_t _is_video_finished;
    SGObjectQueue * _audio_queue;
    SGObjectQueue * _video_queue;
    SGTrack * _selected_video_track;
    NSArray <SGTrack *> * _selected_audio_tracks;
    NSArray <NSNumber *> * _selected_audio_weights;
    NSMutableDictionary <NSNumber *, SGCapacity *> * _capacitys;
}

@property (nonatomic, weak) id <SGPlayerItemDelegate> delegate;
@property (nonatomic, strong) SGFrameFilter * audioFilter;
@property (nonatomic, strong) SGFrameFilter * videoFilter;

@end

@implementation SGPlayerItem

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_capacitys = [NSMutableDictionary dictionary];
        self->_output = [[SGFrameOutput alloc] initWithAsset:asset];
        self->_output.delegate = self;
        self->_audio_queue = [[SGObjectQueue alloc] init];
        self->_audio_queue.delegate = self;
        self->_video_queue = [[SGObjectQueue alloc] init];
        self->_video_queue.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_state != SGPlayerItemStateClosed;
    }, ^SGBlock {
        [self setState:SGPlayerItemStateClosed];
        [self->_output close];
        [self->_audioFilter destroy];
        [self->_videoFilter destroy];
        [self->_audio_queue destroy];
        [self->_video_queue destroy];
        return nil;
    });
}

#pragma mark - Mapping

SGGet0Map(CMTime, duration, self->_output)
SGGet0Map(NSDictionary *, metadata, self->_output)
SGGet0Map(NSArray <SGTrack *> *, tracks, self->_output)

#pragma mark - Setter & Getter

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

- (NSError *)error
{
    __block NSError * ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_error copy];
    });
    return ret;
}

- (SGCapacity *)capacityWithType:(SGMediaType)type
{
    __block SGCapacity * ret = nil;
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
            ret = self->_selected_audio_tracks.count > 0;
        } else if (type == SGMediaTypeVideo) {
            ret = self->_selected_video_track;
        }
    });
    return ret;
}

- (BOOL)isFinished:(SGMediaType)type
{
    __block BOOL ret = NO;
    SGLockEXE00(self->_lock, ^{
        if (type == SGMediaTypeAudio) {
            ret = self->_is_audio_finished;
        } else if (type == SGMediaTypeVideo) {
            ret = self->_is_video_finished;
        }
    });
    return ret;
}

- (BOOL)selectAudioTracks:(NSArray <SGTrack *> *)tracks weights:(NSArray <NSNumber *> *)weights
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return tracks.count > 0 || weights.count > 0;
    }, ^SGBlock {
        SGBlock b1 = ^{};
        if (tracks.count > 0 && ![self->_selected_audio_tracks isEqualToArray:tracks]) {
            self->_selected_audio_weights = nil;
            self->_selected_audio_tracks = [tracks copy];
            NSMutableArray * p = [NSMutableArray arrayWithArray:self->_selected_audio_tracks];
            if (self->_selected_video_track) {
                [p addObject:self->_selected_video_track];
            }
            b1 = ^{
                [self->_output selectTracks:[p copy]];
            };
        }
        if (weights.count > 0 && ![self->_selected_audio_weights isEqualToArray:weights]) {
            self->_selected_audio_weights = [weights copy];
        }
        if (self->_selected_audio_weights.count == 0) {
            NSMutableArray * weights = [NSMutableArray array];
            for (int i = 0; i < tracks.count; i++) {
                [weights addObject:@(100)];
            }
            self->_selected_audio_weights = [weights copy];
        }
        return b1;
    });
}

- (NSArray <SGTrack *> *)selectedAudioTracks
{
    __block NSArray <SGTrack *> * ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_selected_audio_tracks copy];
    });
    return ret;
}

- (NSArray <NSNumber *> *)selectedAudioWeights
{
    __block NSArray <NSNumber *> * ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_selected_audio_weights copy];
    });
    return ret;
}

- (BOOL)selectVideoTrack:(SGTrack *)track
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_selected_video_track != track && track;
    }, ^SGBlock {
        self->_selected_video_track = track;
        NSMutableArray * p = [NSMutableArray arrayWithArray:self->_selected_audio_tracks];
        if (self->_selected_video_track) {
            [p addObject:self->_selected_video_track];
        }
        return ^{
            [self->_output selectTracks:[p copy]];
        };
    });
}

- (SGTrack *)selectedVideoTrack
{
    __block SGTrack * ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = self->_selected_video_track;
    });
    return ret;
}

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state == SGPlayerItemStateNone;
    }, ^SGBlock {
        return [self setState:SGPlayerItemStateOpening];
    }, ^BOOL(SGBlock block) {
        block();
        return [self->_output open];
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
        return [self->_output start];
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
        [self->_output close];
        [self->_audioFilter destroy];
        [self->_videoFilter destroy];
        [self->_audio_queue destroy];
        [self->_video_queue destroy];
        return YES;
    });
}

- (BOOL)seekable
{
    return self->_output.seekable;
}

- (BOOL)seekToTime:(CMTime)time result:(SGSeekResultBlock)result
{
    SGWeakify(self)
    return ![self->_output seekToTime:time result:^(CMTime time, NSError * error) {
        SGStrongify(self)
        if (!error) {
            [self->_audioFilter flush];
            [self->_videoFilter flush];
            SGBlock b1 = [self->_audio_queue flush];
            SGBlock b2 = [self->_video_queue flush];
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
    [self->_audio_queue getObjectAsync:&ret timeReader:timeReader]();
    return ret;
}

- (SGFrame *)copyVideoFrame:(SGTimeReaderBlock)timeReader
{
    SGFrame * ret = nil;
    [self->_video_queue getObjectAsync:&ret timeReader:timeReader]();
    return ret;
}

#pragma mark - SGFrameOutputDelegate

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeState:(SGFrameOutputState)state
{
    switch (state) {
        case SGFrameOutputStateOpened: {
            SGLockEXE10(self->_lock, ^SGBlock {
                NSMutableArray * video = [NSMutableArray array];
                NSMutableArray * audio = [NSMutableArray array];
                NSMutableArray * weight = [NSMutableArray array];
                for (SGTrack * obj in frameOutput.selectedTracks) {
                    if (obj.type == SGMediaTypeAudio) {
                        [audio addObject:obj];
                        [weight addObject:@(100)];
                    } else if (obj.type == SGMediaTypeVideo) {
                        [video addObject:obj];
                    }
                }
                self->_selected_video_track = video.firstObject;
                self->_selected_audio_tracks = [audio copy];
                self->_selected_audio_weights = [weight copy];
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
    __block SGCapacity * additional = nil;
    SGLockEXE00(self->_lock, ^{
        if (track.type == SGMediaTypeAudio) {
            additional = self->_audio_queue.capacity;
        } else if (track.type == SGMediaTypeVideo) {
            additional = self->_video_queue.capacity;
        }
    });
    NSAssert(additional, @"Invalid Additional.");
    [capacity add:additional];
    [self setCapacity:capacity type:track.type];
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(SGFrame *)frame
{
    [frame lock];
    switch (frame.type) {
        case SGMediaTypeAudio: {
            if (self->_audioFilter) {
                frame = [self->_audioFilter convert:frame];
            }
            [self->_audio_queue putObjectSync:frame]();
        }
            break;
        case SGMediaTypeVideo: {
            if (self->_videoFilter) {
                frame = [self->_videoFilter convert:frame];
            }
            [self->_video_queue putObjectSync:frame]();
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
    if (objectQueue == self->_audio_queue) {
        threshold = 5;
        type = SGMediaTypeAudio;
    } else if (objectQueue == self->_video_queue) {
        threshold = 3;
        type = SGMediaTypeVideo;
    }
    NSMutableArray * tracks = [NSMutableArray array];
    for (SGTrack * obj in self->_output.selectedTracks) {
        if (obj.type == type) {
            [tracks addObject:obj];
        }
    }
    if (capacity.count > threshold) {
        [self->_output pause:tracks];
    } else {
        [self->_output resume:tracks];
    }
    NSArray <SGCapacity *> * capacitys = [self->_output capacityWithTrack:tracks];
    SGCapacity * additional = nil;
    for (SGCapacity * obj in capacitys) {
        additional = [obj minimum:additional];
    }
    [capacity add:additional];
    [self setCapacity:capacity type:type];
}

#pragma mark - Capacity

- (BOOL)setCapacity:(SGCapacity *)capacity type:(SGMediaType)type
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        SGCapacity * last = [self->_capacitys objectForKey:@(type)];
        return ![last isEqualToCapacity:capacity];
    }, ^SGBlock {
        [self->_capacitys setObject:capacity forKey:@(type)];
        NSMutableArray * audio_tracks = [NSMutableArray array];
        NSMutableArray * video_tracks = [NSMutableArray array];
        for (SGTrack * obj in self->_output.selectedTracks) {
            if (obj.type == SGMediaTypeAudio) {
                [audio_tracks addObject:obj];
            } else if (obj.type == SGMediaTypeVideo) {
                [video_tracks addObject:obj];
            }
        }
        uint32_t is_audio_finished = 1;
        uint32_t is_video_finished = 1;
        NSArray * finished_tracks = self->_output.finishedTracks;
        SGCapacity * audio_capacity = [self->_capacitys objectForKey:@(SGMediaTypeAudio)];
        SGCapacity * video_capacity = [self->_capacitys objectForKey:@(SGMediaTypeVideo)];
        for (SGTrack * obj in audio_tracks) {
            is_audio_finished = is_audio_finished && [finished_tracks containsObject:obj];
        }
        for (SGTrack * obj in video_tracks) {
            is_video_finished = is_video_finished && [finished_tracks containsObject:obj];
        }
        self->_is_audio_finished = is_audio_finished && (!audio_capacity || audio_capacity.isEmpty);
        self->_is_video_finished = is_video_finished && (!video_capacity || video_capacity.isEmpty);
        if (self->_is_audio_finished && self->_is_video_finished) {
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
