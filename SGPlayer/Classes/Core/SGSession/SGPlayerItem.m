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
#import "SGMapping.h"
#import "SGFFmpeg.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGPlayerItem () <SGFrameOutputDelegate, SGRenderableDelegate>

{
    SGPlayerItemState _state;
}

@property (nonatomic, copy) NSError * error;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, assign) NSUInteger seekingCount;
@property (nonatomic, strong) SGFrameOutput * frameOutput;
@property (nonatomic, weak) id <SGPlayerItemDelegate> delegate;
@property (nonatomic, strong) id <SGRenderable> audioRenderable;
@property (nonatomic, strong) id <SGRenderable> videoRenderable;

@end

@implementation SGPlayerItem

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self.coreLock = [[NSLock alloc] init];
        self.frameOutput = [[SGFrameOutput alloc] initWithAsset:asset];
        self.frameOutput.delegate = self;
    }
    return self;
}

#pragma mark - Interface

- (BOOL)open
{
    SGFFmpegSetupIfNeeded();
    return SGLockEXE(self.coreLock, ^BOOL {
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
    return SGLockEXE(self.coreLock, ^BOOL {
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
    return SGLockEXE(self.coreLock, ^BOOL {
        return self.state != SGPlayerItemStateClosed;
    }, ^SGBasicBlock {
        return [self setState:SGPlayerItemStateClosed];
    }, ^BOOL(SGBasicBlock block) {
        block();
        [self.frameOutput close];
        [self.audioRenderable close];
        [self.videoRenderable close];
        return YES;
    });
}

#pragma mark - Seek

- (BOOL)seeking
{
    return SGLockEXE(self.coreLock, ^BOOL {
        return self.seekingCount != 0;
    }, nil, ^BOOL(SGBasicBlock block) {
        return YES;
    });
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
    return SGLockEXE(self.coreLock, ^BOOL{
        return self.state == SGPlayerItemStateReading || self.state == SGPlayerItemStateFinished;
    }, ^SGBasicBlock{
        self.seekingCount++;
        seekingCount = self.seekingCount;
        return nil;
    }, ^BOOL(SGBasicBlock block) {
        SGWeakSelf
        return ![self.frameOutput seekToTime:time completionHandler:^(CMTime time, NSError * error) {
            SGStrongSelf
            SGLockEXE(self.coreLock, ^BOOL {
                return seekingCount == self.seekingCount;
            }, ^SGBasicBlock {
                self.seekingCount = 0;
                return nil;
            }, ^BOOL(SGBasicBlock block) {
                [self.audioRenderable flush];
                [self.videoRenderable flush];
                if (completionHandler) {
                    completionHandler(time, error);
                }
                return YES;
            });
        }];
    });
}

#pragma mark - Setter & Getter

- (SGBasicBlock)setState:(SGPlayerItemState)state
{
    if (_state != state) {
        _state = state;
        return ^{
            [self.delegate playerItemDidChangeState:self];
        };
    }
    return ^{};
}

SGGet0(SGPlayerItemState, state, _state);
SGGet0Map(CMTime, duration, self.frameOutput);
SGGet0Map(NSDictionary *, metadata, self.frameOutput);
SGGet0Map(NSArray <SGTrack *> *, tracks, self.frameOutput);
SGGet0Map(NSArray <SGTrack *> *, audioTracks, self.frameOutput);
SGGet0Map(NSArray <SGTrack *> *, videoTracks, self.frameOutput);
SGGet0Map(NSArray <SGTrack *> *, otherTracks, self.frameOutput);
SGGet0Map(NSArray <SGTrack *> *, selectedTracks, self.frameOutput);
SGSet1Map(setSelectedTracks, NSArray <SGTrack *> *, self.frameOutput)
SGGet0Map(SGTrack *, selectedAudioTrack, self.frameOutput);
SGGet0Map(SGTrack *, selectedVideoTrack, self.frameOutput);

- (SGCapacity *)capacity
{
    SGCapacity * ret = [[SGCapacity alloc] init];
    SGTrack * track = self.selectedAudioTrack ? self.selectedAudioTrack : self.selectedVideoTrack;
    id <SGRenderable> renderable = self.audioRenderable != SGRenderableStateNone ? self.audioRenderable : self.videoRenderable;
    if (track && renderable) {
        for (SGCapacity * obj in [self capacityWithTracks:@[track] renderables:@[renderable]]) {
            ret.duration = CMTimeAdd(ret.duration, obj.duration);
            ret.size += obj.size;
            ret.count += obj.count;
        }
    }
    return ret;
}

- (NSArray <SGCapacity *> *)capacityWithTracks:(NSArray <SGTrack *> *)tracks renderables:(NSArray <id <SGRenderable>> *)renderables
{
    NSMutableArray * ret = [NSMutableArray array];
    for (SGCapacity * obj in [self.frameOutput capacityWithTracks:tracks]) {
        [ret addObject:obj];
    }
    for (id <SGRenderable> obj in renderables) {
        SGCapacity * c = obj.capacity;
        c.object = obj;
        [ret addObject:c];
    }
    return [ret copy];
}

#pragma mark - SGFrameOutputDelegate

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeState:(SGFrameOutputState)state
{
    switch (state)
    {
        case SGFrameOutputStateOpened:
        {
            SGLockEXE(self.coreLock, nil, ^SGBasicBlock {
                if (self.selectedAudioTrack) {
                    self.audioRenderable.key = YES;
                    self.audioRenderable.delegate = self;
                    [self.audioRenderable open];
                }
                if (self.selectedVideoTrack) {
                    self.videoRenderable.key = !self.selectedAudioTrack;
                    self.videoRenderable.delegate = self;
                    [self.videoRenderable open];
                }
                return [self setState:SGPlayerItemStateOpened];
            }, ^BOOL(SGBasicBlock block) {
                block();
                return YES;
            });
        }
            break;
        case SGFrameOutputStateReading:
        {
            SGLockEXE(self.coreLock, nil, ^SGBasicBlock {
                return [self setState:SGPlayerItemStateReading];
            }, ^BOOL(SGBasicBlock block) {
                block();
                return YES;
            });
        }
            break;
        case SGFrameOutputStateFinished:
            [self callbackForFinisehdIfNeeded];
            break;
        case SGFrameOutputStateFailed:
        {
            self.error = frameOutput.error;
            SGLockEXE(self.coreLock, nil, ^SGBasicBlock {
                return [self setState:SGPlayerItemStateFailed];
            }, ^BOOL(SGBasicBlock block) {
                block();
                return YES;
            });
        }
            break;
        default:
            break;
    }
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeCapacity:(SGCapacity *)capacity track:(SGTrack *)track
{
    [self.delegate playerItemDidChangeCapacity:self];
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(SGFrame *)frame
{
    if (frame.track.type == SGMediaTypeAudio) {
        [self.audioRenderable putFrame:frame];
    } else if (frame.track.type == SGMediaTypeVideo) {
        [self.videoRenderable putFrame:frame];
    }
}

#pragma mark - SGRenderableDelegate

- (void)renderable:(id <SGRenderable>)renderable didChangeState:(SGRenderableState)state
{
    
}

- (void)renderable:(id <SGRenderable>)renderable didChangeCapacity:(SGCapacity *)capacity
{
    if (renderable == self.audioRenderable) {
        if (self.audioRenderable.enough) {
            [self.frameOutput pause:self.frameOutput.audioTracks];
        } else {
            [self.frameOutput resume:self.frameOutput.audioTracks];
        }
    } else if (renderable == self.videoRenderable) {
        if (self.videoRenderable.enough) {
            [self.frameOutput pause:self.frameOutput.videoTracks];
        } else {
            [self.frameOutput resume:self.frameOutput.videoTracks];
        }
    }
    [self.delegate playerItemDidChangeCapacity:self];
    [self callbackForFinisehdIfNeeded];
}

- (void)renderable:(id <SGRenderable>)renderable didRenderFrame:(__kindof SGFrame *)frame
{
    
}

#pragma mark - Callback

- (void)callbackForFinisehdIfNeeded
{
    if ([self finished]) {
        SGLockEXE(self.coreLock, nil, ^SGBasicBlock {
            return [self setState:SGPlayerItemStateFinished];
        }, ^BOOL(SGBasicBlock block) {
            block();
            return YES;
        });
    }
}

- (BOOL)finished
{
    BOOL finished = self.frameOutput.state == SGFrameOutputStateFinished;
    if (finished) {
        finished = finished && self.audioRenderable.capacity.count == 0;
        finished = finished && self.videoRenderable.capacity.count == 0;
    }
    return finished;
}

@end
