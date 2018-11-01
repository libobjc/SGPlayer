//
//  SGPlayer.m
//  SGPlayer
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGPlayer.h"
#import "SGPlayerItem+Internal.h"
#import "SGRenderer+Internal.h"
#import "SGAudioFrameFilter.h"
#import "SGActivity.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGPlayer () <SGPlayerItemDelegate, SGRenderableDelegate>

{
    BOOL _playing;
    BOOL _seeking;
    BOOL _finished;
    CMTime _rate;
    SGPlayerStatus _status;
    SGPlaybackState _playbackState;
    SGLoadingState _loadingState;
}

@property (nonatomic, weak) id <SGPlayerDelegate> delegate;
@property (nonatomic, strong) NSOperationQueue * delegateQueue;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) SGClock * clock;
@property (nonatomic, strong) SGAudioRenderer * audioRenderer;
@property (nonatomic, strong) SGVideoRenderer * videoRenderer;

@property (nonatomic, strong) NSError * error;
@property (nonatomic, strong) SGPlayerItem * currentItem;
@property (nonatomic, assign) CMTime lastPlaybackTime;
@property (nonatomic, assign) CMTime lastLoadedTime;
@property (nonatomic, assign) CMTime lastDuration;

@end

@implementation SGPlayer

- (instancetype)init
{
    if (self = [super init]) {
        [self destroy];
        self.rate = CMTimeMake(1, 1);
        self.delegateQueue = [NSOperationQueue mainQueue];
        self.clock = [[SGClock alloc] init];
        self.audioRenderer = [[SGAudioRenderer alloc] initWithClock:self.clock];
        self.audioRenderer.delegate = self;
        self.audioRenderer.key = YES;
        self.audioRenderer.rate = self.rate;
        self.videoRenderer = [[SGVideoRenderer alloc] initWithClock:self.clock];
        self.videoRenderer.delegate = self;
        self.videoRenderer.key = NO;
        self.videoRenderer.rate = self.rate;
        [self.clock open];
        [self.audioRenderer open];
        [self.videoRenderer open];
    }
    return self;
}

- (void)dealloc
{
    [SGActivity removeTarget:self];
    [self.currentItem close];
    [self.clock close];
    [self.audioRenderer close];
    [self.videoRenderer close];
}

#pragma mark - Asset

- (BOOL)replaceWithURL:(NSURL *)URL
{
    return [self replaceWithAsset:URL ? [[SGURLAsset alloc] initWithURL:URL] : nil];
}

- (BOOL)replaceWithAsset:(SGAsset *)asset
{
    return [self replaceWithPlayerItem:asset ? [[SGPlayerItem alloc] initWithAsset:asset] : nil];
}

- (BOOL)replaceWithPlayerItem:(SGPlayerItem *)item
{
    [self stop];
    if (!item) {
        return NO;
    }
    return SGLockEXE11(self.coreLock, ^SGBlock {
        self->_currentItem = item;
        self->_currentItem.delegate = self;
        self->_currentItem.audioFilter = self.audioRenderer.filter;
        return nil;
    }, ^BOOL(SGBlock block) {
        return [item open];
    });
}

- (void)waitUntilReady
{
    
}

- (BOOL)stop
{
    [self destroy];
    return SGLockEXE11(self.coreLock, ^SGBlock {
        SGBlock b1 = [self setStatus:SGPlayerStatusNone];
        SGBlock b2 = [self setPlaybackState];
        SGBlock b3 = [self setLoadingState:SGLoadingStateNone];
        return ^{
            b1(); b2(); b3();
        };
    }, ^BOOL(SGBlock block) {
        block();
        return YES;
    });
}

- (void)destroy
{
    [SGActivity removeTarget:self];
    __block SGPlayerItem * item = nil;
    SGLockEXE10(self.coreLock, ^SGBlock{
        item = self->_currentItem;
        self->_currentItem = nil;
        self->_playing = NO;
        self->_seeking = NO;
        self->_finished = NO;
        self->_error = nil;
        self->_lastPlaybackTime = CMTimeMake(-1900, 1);
        self->_lastLoadedTime = CMTimeMake(-1900, 1);
        self->_lastDuration = CMTimeMake(-1900, 1);
        return ^{
            [item close];
            [self.clock flush];
            [self.audioRenderer flush];
            [self.videoRenderer flush];
        };
    });
}

#pragma mark - Setter & Getter

- (SGBlock)setStatus:(SGPlayerStatus)status
{
    if (_status == status) {
        return ^{};
    }
    _status = status;
    return ^{
        [self callback:^{
            if ([self.delegate respondsToSelector:@selector(player:didChangeStatus:)]) {
                [self.delegate player:self didChangeStatus:status];
            }
        }];
    };
}

- (SGPlayerStatus)status
{
    __block SGPlayerStatus ret = SGPlayerStatusNone;
    SGLockEXE00(self.coreLock, ^{
        ret = self->_status;
    });
    return ret;
}

- (NSError *)error
{
    __block NSError * ret = nil;
    SGLockEXE00(self.coreLock, ^{
        ret = self->_error;
    });
    return ret;
}

- (SGPlayerItem *)currentItem
{
    __block SGPlayerItem * ret = nil;
    SGLockEXE00(self.coreLock, ^{
        ret = self->_currentItem;
    });
    return ret;
}

SGGet0Map(CMTime, duration, self.currentItem);

- (SGBlock)setPlaybackState
{
    SGPlaybackState playbackState = 0;
    if (_playing) {
        playbackState |= SGPlaybackStatePlaying;
    }
    if (_seeking) {
        playbackState |= SGPlaybackStateSeeking;
    }
    if (_finished) {
        playbackState |= SGPlaybackStateFinished;
    }
    if (_playbackState == playbackState) {
        return ^{};
    }
    _playbackState = playbackState;
    SGBlock renderer = ^{};
    if (_playbackState & SGPlaybackStatePlaying) {
        renderer = ^{
            [self.audioRenderer resume];
            [self.videoRenderer resume];
        };
    } else {
        renderer = ^{
            [self.audioRenderer pause];
            [self.videoRenderer pause];
        };
    }
    return ^{
        renderer();
        [self callback:^{
            if ([self.delegate respondsToSelector:@selector(player:didChangePlaybackState:)]) {
                [self.delegate player:self didChangePlaybackState:playbackState];
            }
        }];
    };
}

- (SGPlaybackState)playbackState
{
    __block SGPlaybackState ret = 0;
    SGLockEXE00(self.coreLock, ^{
        ret = self->_playbackState;
    });
    return ret;
}

- (SGBlock)setLoadingState:(SGLoadingState)loadingState
{
    if (_loadingState == loadingState) {
        return ^{};
    }
    _loadingState = loadingState;
    return ^{
        [self callback:^{
            if ([self.delegate respondsToSelector:@selector(player:didChangeLoadingState:)]) {
                [self.delegate player:self didChangeLoadingState:loadingState];
            }
        }];
    };
}

- (SGLoadingState)loadingState
{
    __block SGLoadingState ret = SGLoadingStateNone;
    SGLockEXE00(self.coreLock, ^{
        ret = self->_loadingState;
    });
    return ret;
}

- (void)setRate:(CMTime)rate
{
    SGLockCondEXE11(self.coreLock, ^BOOL{
        return CMTimeCompare(self->_rate, rate) != 0;
    }, ^SGBlock{
        self->_rate = rate;
        return nil;
    }, ^BOOL(SGBlock block) {
        self.audioRenderer.rate = rate;
        self.videoRenderer.rate = rate;
        return YES;
    });
}

- (CMTime)rate
{
    __block CMTime ret = kCMTimeZero;
    SGLockEXE00(self.coreLock, ^{
        ret = self->_rate;
    });
    return ret;
}

- (void)setFinishedIfNeeded
{
    if (self.currentItem.state == SGPlayerItemStateFinished &&
//        self.audioRenderer.capacity.isEmpty &&
//        self.videoRenderer.capacity.isEmpty) {
        self.audioRenderer.capacity.isEmpty) {
        SGLockEXE10(self.coreLock, ^SGBlock {
            self->_finished = YES;
            return [self setPlaybackState];
        });
    }
}

#pragma mark - Control

- (BOOL)play
{
    [SGActivity addTarget:self];
    return SGLockCondEXE10(self.coreLock, ^BOOL{
        return !self->_error;
    }, ^SGBlock {
        self->_playing = YES;
        return [self setPlaybackState];
    });
}

- (BOOL)pause
{
    [SGActivity removeTarget:self];
    return SGLockCondEXE10(self.coreLock, ^BOOL{
        return !self->_error;
    }, ^SGBlock {
        self->_playing = NO;
        return [self setPlaybackState];
    });
}

SGGet0Map(BOOL, seekable, self.currentItem);

- (BOOL)seekToTime:(CMTime)time result:(SGSeekResultBlock)result
{
    SGWeakSelf
    return [self.currentItem seekToTime:time result:^(CMTime time, NSError * error) {
        SGStrongSelf
        if (!error) {
            [self.clock flush];
            [self.audioRenderer flush];
            [self.videoRenderer flush];
        }
        if (result) {
            [self callback:^{
                result(time, error);
            }];
        }
    }];
}

#pragma mark - Delegate

- (void)callback:(void (^)(void))block
{
    if (!block) {
        return;
    }
    if (self.delegateQueue) {
        NSOperation * operation = [NSBlockOperation blockOperationWithBlock:^{
            block();
        }];
        [self.delegateQueue addOperation:operation];
    } else {
        block();
    }
}

- (void)callbackForTimingIfNeeded
{
//    [self.coreLock lock];
//    if (self.error)
//    {
//        [self.coreLock unlock];
//        return;
//    }
//    [self.coreLock unlock];
//    SGTimeOption option = 0;
//    CMTime playbackTime = self.playbackTime;
//    CMTime loadedTime = self.loadedTime;
//    CMTime duration = self.currentItem.duration;
//    if (CMTIME_IS_VALID(playbackTime) &&
//        CMTimeCompare(playbackTime, self.lastPlaybackTime) != 0)
//    {
//        option |= SGTimeOptionPlayback;
//    }
//    if (CMTIME_IS_VALID(loadedTime) &&
//        CMTimeCompare(loadedTime, self.lastLoadedTime) != 0)
//    {
//        option |= SGTimeOptionLoaded;
//    }
//    if (CMTIME_IS_VALID(duration) &&
//        CMTimeCompare(duration, self.lastDuration) != 0)
//    {
//        option |= SGTimeOptionDuration;
//    }
//    if (option != 0)
//    {
//        self.lastPlaybackTime = playbackTime;
//        self.lastLoadedTime = loadedTime;
//        self.lastDuration = duration;
//        [self callback:^{
//            if ([self.delegate respondsToSelector:@selector(player:didChangeTime:)])
//            {
//                [self.delegate player:self didChangeTime:option];
//            }
//        }];
//    }
}

#pragma mark - SGPlayerItemDelegate

- (void)playerItem:(SGPlayerItem *)playerItem didChangeState:(SGPlayerItemState)state
{
    SGLockEXE10(self.coreLock, ^SGBlock {
        SGBlock before = ^{}, prepare = ^{}, loading = ^{}, playback = ^{}, after = ^{};
        switch (state) {
            case SGPlayerItemStateOpening: {
                prepare = [self setStatus:SGPlayerStatusPreparing];
            }
                break;
            case SGPlayerItemStateOpened: {
                prepare = [self setStatus:SGPlayerStatusReady];
                loading = [self setLoadingState:SGLoadingStateStalled];
                before = ^{
                    [playerItem start];
                };
            }
                break;
            case SGPlayerItemStateReading: {
                self->_finished = NO;
                playback = [self setPlaybackState];
            }
                break;
            case SGPlayerItemStateFinished: {
                loading = [self setLoadingState:SGLoadingStateFinished];
                [self setFinishedIfNeeded];
            }
                break;
            case SGPlayerItemStateFailed: {
                self->_error = playerItem.error;
                prepare = [self setStatus:SGPlayerStatusFailed];
            }
                break;
            default:
                break;
        }
        return ^{
            before(); prepare(); loading(); playback(); after();
        };
    });
}

- (void)playerItem:(SGPlayerItem *)playerItem didChangeCapacity:(SGCapacity *)capacity track:(SGTrack *)track
{
    [self callbackForTimingIfNeeded];
}

#pragma mark - SGRenderableDelegate

- (void)renderable:(id <SGRenderable>)renderable didChangeState:(SGRenderableState)state
{
    
}

- (void)renderable:(id <SGRenderable>)renderable didChangeCapacity:(SGCapacity *)capacity
{
    if (capacity.isEmpty) {
        [self setFinishedIfNeeded];
    }
}

- (__kindof SGFrame *)renderable:(id<SGRenderable>)renderable fetchFrame:(SGTimeReaderBlock)timeReader
{
    if (renderable == self.audioRenderer) {
        return [self.currentItem copyAudioFrame:timeReader];
    } else if (renderable == self.videoRenderer) {
        return [self.currentItem copyVideoFrame:timeReader];
    }
    return nil;
}

@end
