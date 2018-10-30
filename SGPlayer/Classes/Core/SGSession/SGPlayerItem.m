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
#import "SGLock.h"

@interface SGPlayerItem () <SGFrameOutputDelegate, SGObjectQueueDelegate>

{
    SGPlayerItemState _state;
}

@property (nonatomic, copy) NSError * error;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, assign) NSUInteger seekingCount;
@property (nonatomic, strong) SGFrameOutput * frameOutput;
@property (nonatomic, strong) SGObjectQueue * audioQueue;
@property (nonatomic, strong) SGObjectQueue * videoQueue;
@property (nonatomic, strong) SGFrameFilter * audioFilter;
@property (nonatomic, strong) SGFrameFilter * videoFilter;
@property (nonatomic, weak) id <SGPlayerItemDelegate> delegate;

@end

@implementation SGPlayerItem

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self.coreLock = [[NSLock alloc] init];
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
SGGet0Map(NSArray <SGTrack *> *, selectedTracks, self.frameOutput)
SGGet0Map(SGTrack *, selectedAudioTrack, self.frameOutput)
SGGet0Map(SGTrack *, selectedVideoTrack, self.frameOutput)
SGSet1Map(void, setSelectedTracks, NSArray <SGTrack *> *, self.frameOutput)

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE11(self.coreLock, ^BOOL {
        return self.state == SGPlayerItemStateNone;
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
        return self.state == SGPlayerItemStateOpened;
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
        return self.state != SGPlayerItemStateClosed;
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
    return !self.frameOutput.seekable;
}

- (BOOL)seekToTime:(CMTime)time completionHandler:(void (^)(CMTime, NSError *))completionHandler
{
    if (![self seekable]) {
        return NO;
    }
    __block NSUInteger seekingCount = 0;
    return SGLockCondEXE11(self.coreLock, ^BOOL{
        return self.state == SGPlayerItemStateReading || self.state == SGPlayerItemStateFinished;
    }, ^SGBasicBlock{
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
                [self.audioQueue flush];
                [self.videoQueue flush];
                if (completionHandler) {
                    completionHandler(time, error);
                }
                return YES;
            });
        }];
    });
}

- (__kindof SGFrame *)nextAudioFrame
{
    return [self.audioQueue getObjectAsync];
}

- (__kindof SGFrame *)nextVideoFrameWithPTSHandler:(BOOL (^)(CMTime *, CMTime *))ptsHandler drop:(BOOL)drop
{
    return [self.videoQueue getObjectAsyncWithPTSHandler:ptsHandler drop:drop];
}

#pragma mark - Setter & Getter

- (SGBasicBlock)setState:(SGPlayerItemState)state
{
    if (_state == state) {
        return nil;
    }
    _state = state;
    return ^{
        [self.delegate playerItem:self didChangeState:state];
    };
}

- (SGPlayerItemState)state
{
    return _state;
}

- (SGCapacity *)capacity
{
    SGTrack * track = self.selectedAudioTrack ? self.selectedAudioTrack : self.selectedVideoTrack;
    if (track) {
        return [self capacityWithTracks:@[track]].firstObject;
    }
    return [[SGCapacity alloc] init];
}

- (NSArray <SGCapacity *> *)capacityWithTracks:(NSArray <SGTrack *> *)tracks
{
    NSMutableArray * ret = [NSMutableArray array];
    for (SGCapacity * obj in [self.frameOutput capacityWithTracks:tracks]) {
        SGCapacity * o = [obj copy];
        if (((SGTrack *)obj.object).type == SGMediaTypeAudio) {
            [o add:self.audioQueue.capacity];
        } else if (((SGTrack *)obj.object).type == SGMediaTypeVideo) {
            [o add:self.videoQueue.capacity];
        }
        [ret addObject:o];
    }
    return [ret copy];
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
            [self callbackForFinishedIfNeeded];
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
    SGCapacity * additional = nil;
    if (track == self.frameOutput.selectedAudioTrack) {
        additional = self.audioQueue.capacity;
    } else if (track == self.frameOutput.selectedVideoTrack) {
        additional = self.videoQueue.capacity;
    }
    NSAssert(additional, @"Invalid additional.");
    capacity = [capacity copy];
    [capacity add:additional];
    [self.delegate playerItem:self didChangeCapacity:capacity track:track];
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(SGFrame *)frame
{
    [frame lock];
    switch (frame.track.type) {
        case SGMediaTypeAudio: {
            if (self.audioFilter) {
                frame = [self.audioFilter convert:frame];
            }
            [self.audioQueue putObjectSync:frame];
        }
            break;
        case SGMediaTypeVideo: {
            if (self.videoFilter) {
                frame = [self.videoFilter convert:frame];
            }
            [self.videoQueue putObjectSync:frame];
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
    if (capacity.count > threshold) {
        [self.frameOutput pause:@[track]];
    } else {
        [self.frameOutput resume:@[track]];
    }
    capacity = [capacity copy];
    [capacity add:[self.frameOutput capacityWithTracks:@[track]].firstObject];
    [self.delegate playerItem:self didChangeCapacity:capacity track:track];
    [self callbackForFinishedIfNeeded];
}

#pragma mark - Callback

- (void)callbackForFinishedIfNeeded
{
    if (self.frameOutput.state == SGFrameOutputStateFinished &&
        self.audioQueue.capacity.count == 0 &&
        self.videoQueue.capacity.count == 0) {
        SGLockEXE10(self.coreLock, ^SGBasicBlock {
            return [self setState:SGPlayerItemStateFinished];
        });
    }
}

@end
