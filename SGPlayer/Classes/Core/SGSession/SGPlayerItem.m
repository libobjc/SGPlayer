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
#import "SGVideoProcessor.h"
#import "SGObjectQueue.h"
#import "SGFrameOutput.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGPlayerItem () <SGFrameOutputDelegate>

{
    struct {
        NSError *error;
        SGPlayerItemState state;
        BOOL audioFinished;
        BOOL videoFinished;
    } _flags;
    BOOL _capacityFlags[8];
    SGCapacity _capacities[8];
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) SGObjectQueue *audioQueue;
@property (nonatomic, strong, readonly) SGObjectQueue *videoQueue;
@property (nonatomic, strong, readonly) SGFrameOutput *frameOutput;
@property (nonatomic, strong, readonly) SGAudioProcessor *audioProcessor;
@property (nonatomic, strong, readonly) SGVideoProcessor *videoProcessor;

@end

@implementation SGPlayerItem

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_frameOutput = [[SGFrameOutput alloc] initWithAsset:asset];
        self->_frameOutput.delegate = self;
        self->_audioQueue = [[SGObjectQueue alloc] init];
        self->_videoQueue = [[SGObjectQueue alloc] init];
        self->_audioDescriptor = [[SGAudioDescriptor alloc] init];
        for (int i = 0; i < 8; i++) {
            self->_capacityFlags[i] = NO;
            self->_capacities[i] = SGCapacityCreate();
        }
    }
    return self;
}

- (void)dealloc
{
    SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.state != SGPlayerItemStateClosed;
    }, ^SGBlock {
        [self setState:SGPlayerItemStateClosed];
        [self->_frameOutput close];
        SGLockEXE00(self->_lock, ^{
            [self->_audioProcessor close];
            [self->_videoProcessor close];
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
SGGet0Map(SGDemuxerOptions *, demuxerOptions, self->_frameOutput)
SGGet0Map(SGDecoderOptions *, decoderOptions, self->_frameOutput)
SGSet1Map(void, setDemuxerOptions, SGDemuxerOptions *, self->_frameOutput)
SGSet1Map(void, setDecoderOptions, SGDecoderOptions *, self->_frameOutput)

#pragma mark - Setter & Getter

- (SGBlock)setState:(SGPlayerItemState)state
{
    if (self->_flags.state == state) {
        return ^{};
    }
    self->_flags.state = state;
    return ^{
        [self->_delegate playerItem:self didChangeState:state];
    };
}

- (SGPlayerItemState)state
{
    __block SGPlayerItemState ret = SGPlayerItemStateNone;
    SGLockEXE00(self->_lock, ^{
        ret = self->_flags.state;
    });
    return ret;
}

- (NSError *)error
{
    __block NSError *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_flags.error copy];
    });
    return ret;
}

- (SGCapacity)capacityWithType:(SGMediaType)type
{
    __block SGCapacity ret;
    SGLockEXE00(self->_lock, ^{
         ret = self->_capacities[type];
    });
    return ret;
}

- (BOOL)isAvailable:(SGMediaType)type
{
    __block BOOL ret = NO;
    SGLockEXE00(self->_lock, ^{
        if (type == SGMediaTypeAudio) {
            ret = self->_audioSelection.tracks.count > 0;
        } else if (type == SGMediaTypeVideo) {
            ret = self->_videoSelection.tracks.count > 0;
        }
    });
    return ret;
}

- (BOOL)isFinished:(SGMediaType)type
{
    __block BOOL ret = NO;
    SGLockEXE00(self->_lock, ^{
        if (type == SGMediaTypeAudio) {
            ret = self->_flags.audioFinished;
        } else if (type == SGMediaTypeVideo) {
            ret = self->_flags.videoFinished;
        }
    });
    return ret;
}

- (void)setAudioSelection:(SGTrackSelection *)audioSelection action:(SGTrackSelectionAction)action
{
    SGLockEXE10(self->_lock, ^SGBlock {
        self->_audioSelection = [audioSelection copy];
        if (action & SGTrackSelectionActionTracks) {
            NSMutableArray *m = [NSMutableArray array];
            [m addObjectsFromArray:self->_audioSelection.tracks];
            [m addObjectsFromArray:self->_videoSelection.tracks];
            [self->_frameOutput selectTracks:[m copy]];
        }
        if (action > 0) {
            [self->_audioProcessor setSelection:self->_audioSelection action:action];
        }
        return nil;
    });
}

- (void)setVideoSelection:(SGTrackSelection *)videoSelection action:(SGTrackSelectionAction)action
{
    SGLockEXE10(self->_lock, ^SGBlock {
        self->_videoSelection = [videoSelection copy];
        if (action & SGTrackSelectionActionTracks) {
            NSMutableArray *m = [NSMutableArray array];
            [m addObjectsFromArray:self->_audioSelection.tracks];
            [m addObjectsFromArray:self->_videoSelection.tracks];
            [self->_frameOutput selectTracks:[m copy]];
        }
        if (action > 0) {
            [self->_videoProcessor setSelection:self->_videoSelection action:action];
        }
        return nil;
    });
}

#pragma mark - Control

- (BOOL)open
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == SGPlayerItemStateNone;
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
        return self->_flags.state == SGPlayerItemStateOpened;
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
        return self->_flags.state != SGPlayerItemStateClosed;
    }, ^SGBlock {
        return [self setState:SGPlayerItemStateClosed];
    }, ^BOOL(SGBlock block) {
        block();
        [self->_frameOutput close];
        SGLockEXE00(self->_lock, ^{
            [self->_audioProcessor close];
            [self->_videoProcessor close];
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
                [self->_videoProcessor flush];
                [self->_audioQueue flush];
                [self->_videoQueue flush];
                SGBlock b1 = [self setFrameQueueCapacity:SGMediaTypeAudio];
                SGBlock b2 = [self setFrameQueueCapacity:SGMediaTypeVideo];
                return ^{b1(); b2();};
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
        uint64_t discarded = 0;
        BOOL success = [self->_audioQueue getObjectAsync:&ret timeReader:timeReader discarded:&discarded];
        if (success || discarded) {
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
        uint64_t discarded = 0;
        BOOL success = [self->_videoQueue getObjectAsync:&ret timeReader:timeReader discarded:&discarded];
        if (success || discarded) {
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
                    SGTrackSelectionAction action = 0;
                    action |= SGTrackSelectionActionTracks;
                    action |= SGTrackSelectionActionWeights;
                    self->_audioSelection = [[SGTrackSelection alloc] init];
                    self->_audioSelection.tracks = @[audio.firstObject];
                    self->_audioSelection.weights = @[@(1.0)];
                    self->_audioProcessor = [[self->_processorOptions.audioClass alloc] init];
                    [self->_audioProcessor setDescriptor:self->_audioDescriptor];
                    [self->_audioProcessor setSelection:self->_audioSelection action:action];
                }
                if (video.count > 0) {
                    SGTrackSelectionAction action = 0;
                    action |= SGTrackSelectionActionTracks;
                    action |= SGTrackSelectionActionWeights;
                    self->_videoSelection = [[SGTrackSelection alloc] init];
                    self->_videoSelection.tracks = @[video.firstObject];
                    self->_videoSelection.weights = @[@(1.0)];
                    self->_videoProcessor = [[self->_processorOptions.videoClass alloc] init];
                    [self->_videoProcessor setSelection:self->_videoSelection action:action];
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
                SGFrame *aobj = [self->_audioProcessor finish];
                if (aobj) {
                    [self->_audioQueue putObjectSync:aobj];
                    [aobj unlock];
                }
                SGFrame *vobj = [self->_videoProcessor finish];
                if (vobj) {
                    [self->_videoQueue putObjectSync:vobj];
                    [vobj unlock];
                }
                SGBlock b1 = [self setFrameQueueCapacity:SGMediaTypeAudio];
                SGBlock b2 = [self setFrameQueueCapacity:SGMediaTypeVideo];
                SGBlock b3 = [self setFinishedIfNeeded];
                return ^{b1(); b2(); b3();};
            });
        }
            break;
        case SGFrameOutputStateFailed: {
            SGLockEXE10(self->_lock, ^SGBlock {
                self->_flags.error = [frameOutput.error copy];
                return [self setState:SGPlayerItemStateFailed];
            });
        }
            break;
        default:
            break;
    }
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeCapacity:(SGCapacity)capacity type:(SGMediaType)type
{
    SGLockEXE10(self->_lock, ^SGBlock {
        SGCapacity additional = [self frameQueueCapacity:type];
        return [self setCapacity:SGCapacityAdd(capacity, additional) type:type];
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
            obj = [self->_videoProcessor putFrame:obj];
            if (!obj) {
                return nil;
            }
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
    BOOL paused = NO;
    if (type == SGMediaTypeAudio) {
        paused = _audioQueue.capacity.count > 5;
    } else if (type == SGMediaTypeVideo) {
        paused = _videoQueue.capacity.count > 3;
    }
    SGBlock b1 = ^{
        if (paused) {
            [self->_frameOutput pause:type];
        } else {
            [self->_frameOutput resume:type];
        }
    };
    SGCapacity capacity = [self frameQueueCapacity:type];
    SGCapacity additional = [self->_frameOutput capacityWithType:type];
    SGBlock b2 = [self setCapacity:SGCapacityAdd(capacity, additional) type:type];
    return ^{b1(); b2();};
}

- (SGCapacity)frameQueueCapacity:(SGMediaType)type
{
    SGCapacity capacity = SGCapacityCreate();
    if (type == SGMediaTypeAudio) {
        capacity = self->_audioQueue.capacity;
        capacity = SGCapacityAdd(capacity, self->_audioProcessor.capacity);
    } else if (type == SGMediaTypeVideo) {
        capacity = self->_videoQueue.capacity;
        capacity = SGCapacityAdd(capacity, self->_videoProcessor.capacity);
    }
    return capacity;
}

- (SGBlock)setCapacity:(SGCapacity)capacity type:(SGMediaType)type
{
    SGCapacity obj = self->_capacities[type];
    if (SGCapacityIsEqual(obj, capacity)) {
        return ^{};
    }
    self->_capacityFlags[type] = YES;
    self->_capacities[type] = capacity;
    SGBlock b1 = ^{
        [self->_delegate playerItem:self didChangeCapacity:capacity type:type];
    };
    SGBlock b2 = [self setFinishedIfNeeded];
    return ^{b1(); b2();};
}

- (SGBlock)setFinishedIfNeeded
{
    BOOL nomore = self->_frameOutput.state == SGFrameOutputStateFinished;
    SGCapacity ac = self->_capacities[SGMediaTypeAudio];
    SGCapacity vc = self->_capacities[SGMediaTypeVideo];
    self->_flags.audioFinished = nomore && (!self->_capacityFlags[SGMediaTypeAudio] || SGCapacityIsEmpty(ac));
    self->_flags.videoFinished = nomore && (!self->_capacityFlags[SGMediaTypeVideo] || SGCapacityIsEmpty(vc));
    if (self->_flags.audioFinished && self->_flags.videoFinished) {
        return [self setState:SGPlayerItemStateFinished];
    }
    return ^{};
}

@end
