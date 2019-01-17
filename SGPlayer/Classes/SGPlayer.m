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
#import "SGActivity.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGPlayer () <SGClockDelegate, SGRenderableDelegate, SGPlayerItemDelegate>

{
    NSLock *_lock;
    NSCondition *_wakeup;
    
    // Renderer
    SGClock *_clock;
    SGAudioRenderer *_audioRenderer;
    SGVideoRenderer *_videoRenderer;
    
    // Item
    NSError *_error;
    SGPlayerStatus _status;
    SGPlayerItem *_currentItem;
    
    // Loading
    CMTime _loadedTime;
    CMTime _loadedDuration;
    SGLoadingState _loadingState;
    
    // Playback
    CMTime _rate;
    CMTime _currentTime;
    SGPlaybackState _playbackState;
    
    // Flags
    BOOL _playing;
    BOOL _audioFinished;
    BOOL _videoFinished;
    BOOL _audioAvailable;
    BOOL _videoAvailable;
    BOOL _currentTimeValid;
    uint32_t _seekingCount;
}

@property (nonatomic, weak) id<SGPlayerDelegate> delegate;
@property (nonatomic, strong) NSOperationQueue *delegateQueue;

@end

@implementation SGPlayer

- (instancetype)init
{
    if (self = [super init]) {
        [self stop];
        self->_rate = CMTimeMake(1, 1);
        self->_delegateQueue = [NSOperationQueue mainQueue];
        self->_lock = [[NSLock alloc] init];
        self->_wakeup = [[NSCondition alloc] init];
        self->_clock = [[SGClock alloc] init];
        self->_clock.delegate = self;
        self->_audioRenderer = [[SGAudioRenderer alloc] initWithClock:self->_clock];
        self->_audioRenderer.delegate = self;
        self->_videoRenderer = [[SGVideoRenderer alloc] initWithClock:self->_clock];
        self->_videoRenderer.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    [SGActivity removeTarget:self];
    [self->_currentItem close];
    [self->_clock close];
    [self->_audioRenderer close];
    [self->_videoRenderer close];
}

#pragma mark - Setter & Getter

- (SGBlock)setStatus:(SGPlayerStatus)status
{
    if (self->_status == status) {
        return ^{};
    }
    self->_status = status;
    return ^{
        [self->_wakeup lock];
        [self->_wakeup broadcast];
        [self->_wakeup unlock];
        if ([self->_delegate respondsToSelector:@selector(player:didChangeStatus:)]) {
            [self callback:^{
                [self->_delegate player:self didChangeStatus:status];
            }];
        }
    };
}

- (SGPlayerStatus)status
{
    __block SGPlayerStatus ret = SGPlayerStatusNone;
    SGLockEXE00(self->_lock, ^{
        ret = self->_status;
    });
    return ret;
}

- (NSError *)error
{
    __block NSError *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_error copy];
    });
    return ret;
}

- (SGPlayerItem *)currentItem
{
    __block SGPlayerItem *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = self->_currentItem;
    });
    return ret;
}

- (CMTime)duration
{
    __block CMTime ret = kCMTimeZero;
    SGLockEXE00(self->_lock, ^{
        ret = self->_currentItem.duration;
    });
    if (CMTIME_IS_INVALID(ret)) {
        ret = kCMTimeZero;
    }
    return ret;
}

- (SGBlock)setPlaybackState
{
    SGPlaybackState playbackState = 0;
    if (self->_playing) {
        playbackState |= SGPlaybackStatePlaying;
    }
    if (self->_seekingCount > 0) {
        playbackState |= SGPlaybackStateSeeking;
    }
    if (self->_playbackState == SGPlayerStatusReady &&
        (!self->_audioAvailable || self->_audioFinished) &&
        (!self->_videoAvailable || self->_videoFinished)) {
        playbackState |= SGPlaybackStateFinished;
    }
    if (self->_playbackState == playbackState) {
        return ^{};
    }
    self->_playbackState = playbackState;
    SGBlock b1 = ^{}, b2 = ^{}, b3 = ^{};
    if (playbackState & SGPlaybackStateFinished) {
        CMTime duration = self->_currentItem.duration;
        b1 = [self setLoadedTime:duration loadedDuration:kCMTimeZero];
        b2 = [self setCurrentTime:duration];
    }
    if (playbackState & SGPlaybackStateFinished) {
        b3 = ^{
            [self->_audioRenderer finish];
            [self->_videoRenderer finish];
        };
    } else if (playbackState & SGPlaybackStatePlaying) {
        b3 = ^{
            [self->_clock resume];
            [self->_audioRenderer resume];
            [self->_videoRenderer resume];
        };
    } else {
        b3 = ^{
            [self->_clock pause];
            [self->_audioRenderer pause];
            [self->_videoRenderer pause];
        };
    }
    return ^{
        b1(); b2(); b3();
        if ([self->_delegate respondsToSelector:@selector(player:didChangePlaybackState:)]) {
            [self callback:^{
                [self->_delegate player:self didChangePlaybackState:playbackState];
            }];
        }
    };
}

- (SGPlaybackState)playbackState
{
    __block SGPlaybackState ret = 0;
    SGLockEXE00(self->_lock, ^{
        ret = self->_playbackState;
    });
    return ret;
}

- (SGBlock)setLoadingState:(SGLoadingState)loadingState
{
    if (self->_loadingState == loadingState) {
        return ^{};
    }
    self->_loadingState = loadingState;
    return ^{
        if ([self->_delegate respondsToSelector:@selector(player:didChangeLoadingState:)]) {
            [self callback:^{
                [self->_delegate player:self didChangeLoadingState:loadingState];
                
            }];
        }
    };
}

- (SGLoadingState)loadingState
{
    __block SGLoadingState ret = SGLoadingStateNone;
    SGLockEXE00(self->_lock, ^{
        ret = self->_loadingState;
    });
    return ret;
}

- (SGBlock)setCurrentTime:(CMTime)currentTime
{
    if (CMTimeCompare(self->_currentTime, currentTime) == 0) {
        return ^{};
    }
    self->_currentTimeValid = YES;
    self->_currentTime = currentTime;
    CMTime duration = self->_currentItem.duration;
    return ^{
        if ([self->_delegate respondsToSelector:@selector(player:didChangeCurrentTime:duration:)]) {
            [self callback:^{
                [self->_delegate player:self didChangeCurrentTime:currentTime duration:duration];
            }];
        }
    };
}

- (CMTime)currentTime
{
    __block CMTime ret = kCMTimeZero;
    SGLockEXE00(self->_lock, ^{
        ret = self->_currentTime;
    });
    return ret;
}

- (SGBlock)setLoadedTime:(CMTime)loadedTime loadedDuration:(CMTime)loadedDuration
{
    if (CMTimeCompare(self->_loadedTime, loadedTime) == 0 &&
        CMTimeCompare(self->_loadedDuration, loadedDuration) == 0) {
        return ^{};
    }
    self->_loadedTime = loadedTime;
    self->_loadedDuration = loadedDuration;
    return ^{
        if ([self->_delegate respondsToSelector:@selector(player:didChangeLoadedTime:loadedDuuration:)]) {
            [self callback:^{
                [self->_delegate player:self didChangeLoadedTime:loadedTime loadedDuuration:loadedDuration];
            }];
        }
    };
}

- (BOOL)loadedTime:(CMTime *)loadedTime loadedDuration:(CMTime *)loadedDuration
{
    SGLockEXE00(self->_lock, ^{
        if (loadedTime) {
            *loadedTime = self->_loadedTime;
        }
        if (loadedDuration) {
            *loadedDuration = self->_loadedDuration;
        }
    });
    return YES;
}

- (void)setRate:(CMTime)rate
{
    SGLockCondEXE11(self->_lock, ^BOOL {
        return CMTimeCompare(self->_rate, rate) != 0;
    }, ^SGBlock {
        self->_rate = rate;
        return nil;
    }, ^BOOL(SGBlock block) {
        self->_clock.rate = rate;
        self->_audioRenderer.rate = rate;
        self->_videoRenderer.rate = rate;
        return YES;
    });
}

- (CMTime)rate
{
    __block CMTime ret = kCMTimeZero;
    SGLockEXE00(self->_lock, ^{
        ret = self->_rate;
    });
    return ret;
}

- (SGClock *)clock
{
    __block SGClock *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = self->_clock;
    });
    return ret;
}

- (SGAudioRenderer *)audioRenderer
{
    __block SGAudioRenderer *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = self->_audioRenderer;
    });
    return ret;
}

- (SGVideoRenderer *)videoRenderer
{
    __block SGVideoRenderer *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = self->_videoRenderer;
    });
    return ret;
}

#pragma mark - Item

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
    return SGLockEXE11(self->_lock, ^SGBlock {
        self->_currentItem = item;
        self->_currentItem.delegate = self;
        self->_currentItem.audioDescription = self->_audioRenderer.audioDescription;
        return nil;
    }, ^BOOL(SGBlock block) {
        return [item open];
    });
}

- (void)waitUntilReady
{
    [self->_wakeup lock];
    while (YES) {
        BOOL ret = SGLockCondEXE00(self->_lock, ^BOOL {
            return self->_status == SGPlayerStatusPreparing;
        }, nil);
        if (ret) {
            [self->_wakeup wait];
            continue;
        }
        break;
    }
    [self->_wakeup unlock];
}

- (BOOL)stop
{
    [SGActivity removeTarget:self];
    return SGLockEXE10(self->_lock, ^SGBlock {
        SGPlayerItem *currentItem = self->_currentItem;
        self->_playing = NO;
        self->_seekingCount = 0;
        self->_audioFinished = NO;
        self->_videoFinished = NO;
        self->_audioAvailable = NO;
        self->_videoAvailable = NO;
        self->_currentTimeValid = NO;
        self->_currentTime = kCMTimeInvalid;
        self->_loadedTime = kCMTimeInvalid;
        self->_loadedDuration = kCMTimeInvalid;
        self->_status = SGPlayerStatusNone;
        self->_loadingState = SGLoadingStateNone;
        self->_playbackState = 0;
        self->_error = nil;
        self->_currentItem = nil;
        SGBlock b1 = [self setStatus:SGPlayerStatusNone];
        SGBlock b2 = [self setPlaybackState];
        SGBlock b3 = [self setLoadingState:SGLoadingStateNone];
        return ^{
            [currentItem close];
            [self->_clock close];
            [self->_audioRenderer close];
            [self->_videoRenderer close];
            b1(); b2(); b3();
        };
    });
}

#pragma mark - Playback

- (BOOL)play
{
    [SGActivity addTarget:self];
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_status == SGPlayerStatusReady;
    }, ^SGBlock {
        self->_playing = YES;
        return [self setPlaybackState];
    });
}

- (BOOL)pause
{
    [SGActivity removeTarget:self];
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_status == SGPlayerStatusReady;
    }, ^SGBlock {
        self->_playing = NO;
        return [self setPlaybackState];
    });
}

-  (BOOL)seekable
{
    SGPlayerItem *currentItem = [self currentItem];
    return [currentItem seekable];
}

- (BOOL)seekToTime:(CMTime)time result:(SGSeekResult)result
{
    __block uint32_t seekingCount = 0;
    __block SGPlayerItem *currentItem = nil;
    BOOL ret = SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_status == SGPlayerStatusReady;
    }, ^SGBlock {
        self->_seekingCount += 1;
        currentItem = self->_currentItem;
        seekingCount = self->_seekingCount;
        return [self setPlaybackState];
    });
    if (!ret) {
        return NO;
    }
    SGWeakify(self)
    return [currentItem seekToTime:time result:^(CMTime time, NSError *error) {
        SGStrongify(self)
        SGLockCondEXE11(self->_lock, ^BOOL {
            return seekingCount == self->_seekingCount;
        }, ^SGBlock {
            SGBlock b1 = ^{}, b2 = ^{};
            self->_seekingCount = 0;
            if (!error) {
                self->_audioFinished = NO;
                self->_videoFinished = NO;
                self->_currentTimeValid = NO;
                b1 = ^{
                    [self->_clock flush];
                    [self->_audioRenderer flush];
                    [self->_videoRenderer flush];
                };
            }
            b2 = [self setPlaybackState];
            return ^{
                b1(); b2();
            };
        }, ^BOOL(SGBlock block) {
            block();
            if (result) {
                [self callback:^{
                    result(time, error);
                }];
            }
            return YES;
        });
    }];
}

#pragma mark - SGClockDelegate

- (void)clock:(SGClock *)clock didChcnageCurrentTime:(CMTime)currentTime
{
    SGLockEXE10(self->_lock, ^SGBlock {
        return [self setCurrentTime:currentTime];
    });
}

#pragma mark - SGRenderableDelegate

- (void)renderable:(id<SGRenderable>)renderable didChangeState:(SGRenderableState)state
{
    NSAssert(state != SGRenderableStateFailed, @"Invaild renderer, %@", renderable);
}

- (void)renderable:(id<SGRenderable>)renderable didChangeCapacity:(SGCapacity *)capacity
{
    if (capacity.isEmpty) {
        SGLockEXE10(self->_lock, ^SGBlock {
            if (self->_audioRenderer.capacity.isEmpty && [self->_currentItem isFinished:SGMediaTypeAudio]) {
                self->_audioFinished = YES;
            }
            if (self->_videoRenderer.capacity.isEmpty && [self->_currentItem isFinished:SGMediaTypeVideo]) {
                self->_videoFinished = YES;
            }
            return [self setPlaybackState];
        });
    }
}

- (__kindof SGFrame *)renderable:(id<SGRenderable>)renderable fetchFrame:(SGTimeReader)timeReader
{
    SGPlayerItem *currentItem = self.currentItem;
    if (renderable == self->_audioRenderer) {
        return [currentItem copyAudioFrame:timeReader];
    } else if (renderable == self->_videoRenderer) {
        return [currentItem copyVideoFrame:timeReader];
    }
    return nil;
}

#pragma mark - SGPlayerItemDelegate

- (void)playerItem:(SGPlayerItem *)playerItem didChangeState:(SGPlayerItemState)state
{
    SGLockEXE10(self->_lock, ^SGBlock {
        SGBlock b1 = ^{}, b2 = ^{}, b3 = ^{}, b4 = ^{};
        switch (state) {
            case SGPlayerItemStateOpening: {
                b1 = [self setStatus:SGPlayerStatusPreparing];
            }
                break;
            case SGPlayerItemStateOpened: {
                b2 = [self setStatus:SGPlayerStatusReady];
                b3 = [self setLoadingState:SGLoadingStateStalled];
                b4 = [self setCurrentTime:kCMTimeZero];
                b1 = ^{
                    [self->_clock open];
                    if ([playerItem isAvailable:SGMediaTypeAudio]) {
                        self->_audioAvailable = YES;
                        [self->_audioRenderer open];
                    }
                    if ([playerItem isAvailable:SGMediaTypeVideo]) {
                        self->_videoAvailable = YES;
                        [self->_videoRenderer open];
                    }
                    [playerItem start];
                };
            }
                break;
            case SGPlayerItemStateReading: {
                b1 = [self setPlaybackState];
            }
                break;
            case SGPlayerItemStateFinished: {
                b1 = [self setLoadingState:SGLoadingStateFinished];
                if (self->_audioRenderer.capacity.isEmpty) {
                    self->_audioFinished = YES;
                }
                if (self->_videoRenderer.capacity.isEmpty) {
                    self->_videoFinished = YES;
                }
                b2 = [self setPlaybackState];
            }
                break;
            case SGPlayerItemStateFailed: {
                self->_error = [playerItem.error copy];
                b1 = [self setStatus:SGPlayerStatusFailed];
            }
                break;
            default:
                break;
        }
        return ^{
            b1(); b2(); b3();; b4();
        };
    });
}

- (void)playerItem:(SGPlayerItem *)playerItem didChangeCapacity:(SGCapacity *)capacity type:(SGMediaType)type
{
    BOOL should = NO;
    if (type == SGMediaTypeAudio &&
        ![playerItem isFinished:SGMediaTypeAudio]) {
        should = YES;
    } else if (type == SGMediaTypeVideo &&
               ![playerItem isFinished:SGMediaTypeVideo] &&
               (![playerItem isAvailable:SGMediaTypeAudio] || [playerItem isFinished:SGMediaTypeAudio])) {
        should = YES;
    }
    if (should) {
        SGLockCondEXE10(self->_lock, ^BOOL {
            return self->_currentTimeValid;
        }, ^SGBlock {
            CMTime duration = capacity.duration;
            CMTime time = CMTimeAdd(self->_currentTime, duration);
            SGBlock b1 = [self setLoadedTime:time loadedDuration:duration];
            SGBlock b2 = [self setLoadingState:(capacity.isEmpty || self->_loadingState == SGLoadingStateFinished) ? SGLoadingStateStalled : SGLoadingStatePlaybale];
            return ^{
                b1(); b2();
            };
        });
    }
}

#pragma mark - Delegate

- (void)callback:(void (^)(void))block
{
    if (!block) {
        return;
    }
    if (self->_delegateQueue) {
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            block();
        }];
        [self->_delegateQueue addOperation:operation];
    } else {
        block();
    }
}

@end
