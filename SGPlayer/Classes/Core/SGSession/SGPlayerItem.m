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
}

@property (nonatomic, weak) id <SGPlayerItemDelegate> delegate;
@property (nonatomic, strong) NSError * error;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, assign) NSUInteger seekingCount;
@property (nonatomic, strong) SGPointerMap * capacityMap;
@property (nonatomic, strong) SGFrameOutput * frameOutput;
@property (nonatomic, strong) SGObjectQueue * audioQueue;
@property (nonatomic, strong) SGObjectQueue * videoQueue;
@property (nonatomic, strong) SGFrameFilter * audioFilter;
@property (nonatomic, strong) SGFrameFilter * videoFilter;
@property (nonatomic, assign) BOOL audioFinished;
@property (nonatomic, assign) BOOL videoFinished;

@end

@implementation SGPlayerItem

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self.coreLock = [[NSLock alloc] init];
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
SGGet0Map(SGTrack *, selectedAudioTrack, self.frameOutput)
SGGet0Map(SGTrack *, selectedVideoTrack, self.frameOutput)
SGSet1Map(void, setSelectedAudioTrack, SGTrack *, self.frameOutput)
SGSet1Map(void, setSelectedVideoTrack, SGTrack *, self.frameOutput)

#pragma mark - Setter & Getter

- (SGBasicBlock)setState:(SGPlayerItemState)state
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
    SGLockEXE00(self.coreLock, ^{
        ret = self->_state;
    });
    return ret;
}

- (SGCapacity *)capacity
{
    SGTrack * track = self.selectedAudioTrack ? self.selectedAudioTrack : self.selectedVideoTrack;
    return [self capacityWithTrack:track];
}

- (SGCapacity *)capacityWithTrack:(SGTrack *)track
{
    __block SGCapacity * ret = nil;
    SGLockEXE00(self.coreLock, ^{
         ret = [[self.capacityMap objectForKey:track] copy];
    });
    return ret ? ret : [[SGCapacity alloc] init];
}

- (BOOL)setCapacity:(SGCapacity *)capacity track:(SGTrack *)track
{
    if (self.frameOutput.state == SGFrameOutputStateFinished && capacity.count == 0) {
        if (track.type == SGMediaTypeAudio) {
            self.audioFinished = YES;
        } else if (track.type == SGMediaTypeVideo) {
            self.videoFinished = YES;
        }
    }
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        SGCapacity * last = [self.capacityMap objectForKey:track];
        return ![last isEqualToCapacity:capacity];
    }, ^SGBasicBlock {
        [self.capacityMap setObject:capacity forKey:track];
        return nil;
    }, ^BOOL(SGBasicBlock block) {
        [self.delegate playerItem:self didChangeCapacity:[capacity copy] track:track];
        return YES;
    });
}

- (void)setFinishedIfNeeded
{
    if (self.frameOutput.state == SGFrameOutputStateFinished &&
        (!self.selectedAudioTrack || self.audioFinished) &&
        (!self.selectedVideoTrack || self.videoFinished)) {
        SGLockEXE10(self.coreLock, ^SGBasicBlock {
            return [self setState:SGPlayerItemStateFinished];
        });
    }
}

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state == SGPlayerItemStateNone;
    }, ^SGBasicBlock {
        return [self setState:SGPlayerItemStateOpening];
    }, ^BOOL(SGBasicBlock block) {
        block();
        return ![self.frameOutput open];
    });
}

- (BOOL)start
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state == SGPlayerItemStateOpened;
    }, ^SGBasicBlock {
        return [self setState:SGPlayerItemStateReading];;
    }, ^BOOL(SGBasicBlock block) {
        block();
        return ![self.frameOutput start];
    });
}

- (BOOL)close
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state != SGPlayerItemStateClosed;
    }, ^SGBasicBlock {
        return [self setState:SGPlayerItemStateClosed];
    }, ^BOOL(SGBasicBlock block) {
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

- (BOOL)seeking
{
    return SGLockCondEXE00(self.coreLock, ^BOOL {
        return self.seekingCount != 0;
    }, nil);
}

- (BOOL)seekable
{
    return self.frameOutput.seekable;
}

- (BOOL)seekToTime:(CMTime)time completionHandler:(void (^)(CMTime, NSError *))completionHandler
{
    if (![self seekable]) {
        return NO;
    }
    __block NSUInteger seekingCount = 0;
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self->_state == SGPlayerItemStateReading || self->_state == SGPlayerItemStateFinished;
    }, ^SGBasicBlock {
        self.seekingCount++;
        seekingCount = self.seekingCount;
        return nil;
    }, ^BOOL(SGBasicBlock block) {
        SGWeakSelf
        return ![self.frameOutput seekToTime:time completionHandler:^(CMTime time, NSError * error) {
            SGStrongSelf
            SGLockCondEXE11(self.coreLock, ^BOOL {
                return seekingCount == self.seekingCount;
            }, ^SGBasicBlock {
                self.seekingCount = 0;
                return nil;
            }, ^BOOL(SGBasicBlock block) {
                [self.audioFilter flush];
                [self.videoFilter flush];
                [self.audioQueue flush]();
                [self.videoQueue flush]();
                if (completionHandler) {
                    completionHandler(time, error);
                }
                return YES;
            });
        }];
    });
}

- (SGFrame *)copyAudioFrame:(SGClockBlock)clock
{
    SGFrame * ret = nil;
    [self.audioQueue getObjectAsync:&ret clock:clock]();
    return ret;
}

- (SGFrame *)copyVideoFrame:(SGClockBlock)clock
{
    SGFrame * ret = nil;
    [self.videoQueue getObjectAsync:&ret clock:clock]();
    return ret;
}

#pragma mark - SGFrameOutputDelegate

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeState:(SGFrameOutputState)state
{
    switch (state) {
        case SGFrameOutputStateOpened: {
            SGLockEXE10(self.coreLock, ^SGBasicBlock {
                return [self setState:SGPlayerItemStateOpened];
            });
        }
            break;
        case SGFrameOutputStateReading: {
            SGLockEXE10(self.coreLock, ^SGBasicBlock {
                return [self setState:SGPlayerItemStateReading];
            });
        }
            break;
        case SGFrameOutputStateFinished:
            [self setFinishedIfNeeded];
            break;
        case SGFrameOutputStateFailed: {
            self.error = frameOutput.error;
            SGLockEXE10(self.coreLock, ^SGBasicBlock {
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
    SGCapacity * additional = nil;
    if (track == self.frameOutput.selectedAudioTrack) {
        additional = self.audioQueue.capacity;
    } else if (track == self.frameOutput.selectedVideoTrack) {
        additional = self.videoQueue.capacity;
    }
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
    SGTrack * track = nil;
    NSUInteger threshold = 0;
    if (objectQueue == self.audioQueue) {
        track = self.frameOutput.selectedAudioTrack;
        threshold = 5;
    } else if (objectQueue == self.videoQueue) {
        track = self.frameOutput.selectedVideoTrack;
        threshold = 3;
    }
    NSAssert(track, @"Invalid track.");
    capacity = [capacity copy];
    if (capacity.count > threshold) {
        [self.frameOutput pause:track.type];
    } else {
        [self.frameOutput resume:track.type];
    }
    SGCapacity * additional = [self.frameOutput capacityWithTrack:track];
    [capacity add:additional];
    [self setCapacity:capacity track:track];
    [self setFinishedIfNeeded];
}

@end
