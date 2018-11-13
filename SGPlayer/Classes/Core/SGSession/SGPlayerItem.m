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
#import "SGPointerMap.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGPlayerItem () <SGFrameOutputDelegate, SGObjectQueueDelegate>

{
    SGPlayerItemState _state;
    BOOL _audio_finished;
    BOOL _video_finished;
    __strong NSError * _error;
    __strong SGTrack * _selected_audio_track;
    __strong SGTrack * _selected_video_track;
}

@property (nonatomic, weak) id <SGPlayerItemDelegate> delegate;
@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) SGPointerMap * capacityMap;
@property (nonatomic, strong) SGFrameOutput * frameOutput;
@property (nonatomic, strong) SGObjectQueue * audioQueue;
@property (nonatomic, strong) SGObjectQueue * videoQueue;
@property (nonatomic, strong) SGFrameFilter * audioFilter;
@property (nonatomic, strong) SGFrameFilter * videoFilter;

@end

@implementation SGPlayerItem

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self.lock = [[NSLock alloc] init];
        self.capacityMap = [[SGPointerMap alloc] init];
        self.frameOutput = [[SGFrameOutput alloc] initWithAsset:asset];
        self.frameOutput.delegate = self;
        self.audioQueue = [[SGObjectQueue alloc] init];
        self.audioQueue.delegate = self;
        self.videoQueue = [[SGObjectQueue alloc] init];
        self.videoQueue.delegate = self;
        self.videoQueue.shouldSortObjects = YES;
    }
    return self;
}

#pragma mark - Mapping

SGGet0Map(CMTime, duration, self.frameOutput)
SGGet0Map(NSDictionary *, metadata, self.frameOutput)
SGGet0Map(NSArray <SGTrack *> *, tracks, self.frameOutput)
SGGet0Map(NSArray <SGTrack *> *, audioTracks, self.frameOutput)
SGGet0Map(NSArray <SGTrack *> *, videoTracks, self.frameOutput)
SGGet0Map(NSArray <SGTrack *> *, otherTracks, self.frameOutput)

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

- (BOOL)audioFinished
{
    __block BOOL ret = NO;
    SGLockEXE00(self.lock, ^{
        ret = self->_audio_finished;
    });
    return ret;
}

- (BOOL)videoFinished
{
    __block BOOL ret = NO;
    SGLockEXE00(self.lock, ^{
        ret = self->_video_finished;
    });
    return ret;
}

- (void)setSelectedAudioTrack:(SGTrack *)selectedAudioTrack
{
    SGLockCondEXE11(self.lock, ^BOOL {
        return self->_selected_audio_track != selectedAudioTrack;
    }, ^SGBlock {
        self->_selected_audio_track = selectedAudioTrack;
        return nil;
    }, ^BOOL(SGBlock block) {
        self.frameOutput.selectedAudioTrack = selectedAudioTrack;
        return YES;
    });
}

- (SGTrack *)selectedAudioTrack
{
    __block SGTrack * ret = nil;
    SGLockEXE00(self.lock, ^{
        ret = self->_selected_audio_track;
    });
    return ret;
}

- (void)setSelectedVideoTrack:(SGTrack *)selectedVideoTrack
{
    SGLockCondEXE11(self.lock, ^BOOL {
        return self->_selected_video_track != selectedVideoTrack;
    }, ^SGBlock {
        self->_selected_video_track = selectedVideoTrack;
        return nil;
    }, ^BOOL(SGBlock block) {
        self.frameOutput.selectedVideoTrack = selectedVideoTrack;
        return YES;
    });
}

- (SGTrack *)selectedVideoTrack
{
    __block SGTrack * ret = nil;
    SGLockEXE00(self.lock, ^{
        ret = self->_selected_video_track;
    });
    return ret;
}

- (SGCapacity *)capacity
{
    return [self capacityWithTrack:nil];
}

- (SGCapacity *)capacityWithTrack:(SGTrack *)track
{
    __block SGCapacity * ret = nil;
    SGLockEXE00(self.lock, ^{
        SGTrack * t = track ? track : (self->_selected_audio_track ? self->_selected_audio_track : self->_selected_video_track);
         ret = [[self.capacityMap objectForKey:t] copy];
    });
    return ret ? ret : [[SGCapacity alloc] init];
}

- (BOOL)setCapacity:(SGCapacity *)capacity track:(SGTrack *)track
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        SGCapacity * last = [self.capacityMap objectForKey:track];
        return ![last isEqualToCapacity:capacity];
    }, ^SGBlock {
        [self.capacityMap setObject:capacity forKey:track];
        SGCapacity * audio_capacity = track == self->_selected_audio_track ? capacity : [self.capacityMap objectForKey:self->_selected_audio_track];
        SGCapacity * video_capacity = track == self->_selected_video_track ? capacity : [self.capacityMap objectForKey:self->_selected_video_track];
        self->_audio_finished = audio_capacity.isEmpty && self.frameOutput.audioFinished;
        self->_video_finished = video_capacity.isEmpty && self.frameOutput.videoFinished;
        if (self->_audio_finished && self->_video_finished) {
            return [self setState:SGPlayerItemStateFinished];
        }
        return nil;
    }, ^BOOL(SGBlock block) {
        [self.delegate playerItem:self didChangeCapacity:[capacity copy] track:track];
        block();
        return YES;
    });
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
                self->_selected_audio_track = frameOutput.selectedAudioTrack;
                self->_selected_video_track = frameOutput.selectedVideoTrack;
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

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeCapacity:(SGCapacity *)capacity track:(SGTrack *)track
{
    capacity = [capacity copy];
    __block SGCapacity * additional = nil;
    SGLockEXE00(self.lock, ^{
        if (track == self->_selected_audio_track) {
            additional = self.audioQueue.capacity;
        } else if (track == self->_selected_video_track) {
            additional = self.videoQueue.capacity;
        }
    });
    NSAssert(additional, @"Invalid additional.");
    [capacity add:additional];
    [self setCapacity:capacity track:track];
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(SGFrame *)frame
{
    [frame lock];
    switch (frame.track.type) {
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
    __block SGTrack * track = nil;
    __block uint32_t threshold = 0;
    SGLockEXE00(self.lock, ^{
        if (objectQueue == self.audioQueue) {
            track = self->_selected_audio_track;
            threshold = 5;
        } else if (objectQueue == self.videoQueue) {
            track = self->_selected_video_track;
            threshold = 3;
        }
    });
    if (!track) {
        return;
    }
    capacity = [capacity copy];
    if (capacity.count > threshold) {
        [self.frameOutput pause:track.type];
    } else {
        [self.frameOutput resume:track.type];
    }
    SGCapacity * additional = [self.frameOutput capacityWithTrack:track];
    [capacity add:additional];
    [self setCapacity:capacity track:track];
}

@end
