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
    int32_t _is_playing;
    int32_t _is_seeking;
    int32_t _is_audio_available;
    int32_t _is_video_available;
    int32_t _is_audio_finished;
    int32_t _is_video_finished;
    int32_t _is_current_time_valid;
    CMTime _rate;
    CMTime _loaded_time;
    CMTime _current_time;
    CMTime _loaded_duration;
    SGPlayerStatus _status;
    SGLoadingState _loading_state;
    SGPlaybackState _playback_state;
    __strong NSError * _error;
    __strong SGPlayerItem * _current_item;
}

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) SGClock * clock;
@property (nonatomic, strong) NSCondition * waitCondition;
@property (nonatomic, strong) SGAudioRenderer * audioRenderer;
@property (nonatomic, strong) SGVideoRenderer * videoRenderer;

@property (nonatomic, weak) id <SGPlayerDelegate> delegate;
@property (nonatomic, strong) NSOperationQueue * delegateQueue;

@end

@implementation SGPlayer

- (instancetype)init
{
    if (self = [super init]) {
        [self stop];
        self->_rate = CMTimeMake(1, 1);
        self.delegateQueue = [NSOperationQueue mainQueue];
        self.lock = [[NSLock alloc] init];
        self.clock = [[SGClock alloc] init];
        self.clock.delegate = self;
        self.waitCondition = [[NSCondition alloc] init];
        self.audioRenderer = [[SGAudioRenderer alloc] initWithClock:self.clock];
        self.audioRenderer.delegate = self;
        self.audioRenderer.key = YES;
        self.videoRenderer = [[SGVideoRenderer alloc] initWithClock:self.clock];
        self.videoRenderer.delegate = self;
        self.videoRenderer.key = NO;
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
    return SGLockEXE11(self.lock, ^SGBlock {
        self->_current_item = item;
        self->_current_item.delegate = self;
        self->_current_item.audioFilter = self.audioRenderer.filter;
        return nil;
    }, ^BOOL(SGBlock block) {
        return [item open];
    });
}

- (void)waitUntilReady
{
    [self.waitCondition lock];
    while (YES) {
        BOOL ret = SGLockCondEXE00(self.lock, ^BOOL {
            return self->_status == SGPlayerStatusPreparing;
        }, nil);
        if (ret) {
            [self.waitCondition wait];
            continue;
        }
        break;
    }
    [self.waitCondition unlock];
}

- (BOOL)stop
{
    [SGActivity removeTarget:self];
    return SGLockEXE10(self.lock, ^SGBlock {
        SGPlayerItem * item = self->_current_item;
        self->_is_playing = 0;
        self->_is_seeking = 0;
        self->_is_audio_available = 0;
        self->_is_video_available = 0;
        self->_is_audio_finished = 0;
        self->_is_video_finished = 0;
        self->_is_current_time_valid = 0;
        self->_current_time = kCMTimeInvalid;
        self->_loaded_time = kCMTimeInvalid;
        self->_loaded_duration = kCMTimeInvalid;
        self->_status = SGPlayerStatusNone;
        self->_loading_state = SGLoadingStateNone;
        self->_playback_state = 0;
        self->_error = nil;
        self->_current_item = nil;
        SGBlock b1 = [self setStatus:SGPlayerStatusNone];
        SGBlock b2 = [self setPlaybackState];
        SGBlock b3 = [self setLoadingState:SGLoadingStateNone];
        return ^{
            [item close];
            [self.clock close];
            [self.audioRenderer close];
            [self.videoRenderer close];
            b1(); b2(); b3();
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
        [self.waitCondition lock];
        [self.waitCondition broadcast];
        [self.waitCondition unlock];
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
    SGLockEXE00(self.lock, ^{
        ret = self->_status;
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

- (SGPlayerItem *)currentItem
{
    __block SGPlayerItem * ret = nil;
    SGLockEXE00(self.lock, ^{
        ret = self->_current_item;
    });
    return ret;
}

- (CMTime)duration
{
    CMTime ret = self.currentItem.duration;
    if (CMTIME_IS_VALID(ret)) {
        return ret;
    }
    return kCMTimeZero;
}

- (SGBlock)setPlaybackState
{
    SGPlaybackState playbackState = 0;
    if (_is_playing) {
        playbackState |= SGPlaybackStatePlaying;
    }
    if (_is_seeking) {
        playbackState |= SGPlaybackStateSeeking;
    }
    if ((!_is_audio_available || _is_audio_finished) &&
        (!_is_video_available ||  _is_video_finished)) {
        playbackState |= SGPlaybackStateFinished;
    }
    if (_playback_state == playbackState) {
        return ^{};
    }
    _playback_state = playbackState;
    SGBlock b1 = ^{}, b2 = ^{}, b3 = ^{};
    if (playbackState & SGPlaybackStateFinished) {
        CMTime duration = self->_current_item.duration;
        b1 = [self setLoadedTime:duration loadedDuration:kCMTimeZero];
        b2 = [self setCurrentTime:duration];
    }
    if (playbackState & SGPlaybackStatePlaying) {
        b3 = ^{
            [self.audioRenderer resume];
            [self.videoRenderer resume];
        };
    } else {
        b3 = ^{
            [self.audioRenderer pause];
            [self.videoRenderer pause];
        };
    }
    return ^{
        b1(); b2(); b3();
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
    SGLockEXE00(self.lock, ^{
        ret = self->_playback_state;
    });
    return ret;
}

- (SGBlock)setLoadingState:(SGLoadingState)loadingState
{
    if (_loading_state == loadingState) {
        return ^{};
    }
    _loading_state = loadingState;
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
    SGLockEXE00(self.lock, ^{
        ret = self->_loading_state;
    });
    return ret;
}

- (SGBlock)setCurrentTime:(CMTime)currentTime
{
    if (CMTimeCompare(_current_time, currentTime) == 0) {
        return ^{};
    }
    _is_current_time_valid = 1;
    _current_time = currentTime;
    CMTime duration = self->_current_item.duration;
    return ^{
        [self callback:^{
            if ([self.delegate respondsToSelector:@selector(player:didChangeCurrentTime:duration:)]) {
                [self.delegate player:self didChangeCurrentTime:currentTime duration:duration];
            }
        }];
    };
}

- (CMTime)currentTime
{
    __block CMTime ret = kCMTimeZero;
    SGLockEXE00(self.lock, ^{
        ret = self->_current_time;
    });
    return ret;
}

- (SGBlock)setLoadedTime:(CMTime)loadedTime loadedDuration:(CMTime)loadedDuration
{
    if (CMTimeCompare(_loaded_time, loadedTime) == 0 && CMTimeCompare(_loaded_duration, loadedDuration) == 0) {
        return ^{};
    }
    _loaded_time = loadedTime;
    _loaded_duration = loadedDuration;
    return ^{
        [self callback:^{
            if ([self.delegate respondsToSelector:@selector(player:didChangeLoadedTime:loadedDuuration:)]) {
                [self.delegate player:self didChangeLoadedTime:loadedTime loadedDuuration:loadedDuration];
            }
        }];
    };
}

- (BOOL)loadedTime:(CMTime *)loadedTime loadedDuration:(CMTime *)loadedDuration
{
    SGLockEXE00(self.lock, ^{
        if (loadedTime) {
            * loadedTime = self->_loaded_time;
        }
        if (loadedDuration) {
            * loadedDuration = self->_loaded_duration;
        }
    });
    return YES;
}

- (void)setRate:(CMTime)rate
{
    SGLockCondEXE11(self.lock, ^BOOL {
        return CMTimeCompare(self->_rate, rate) != 0;
    }, ^SGBlock {
        self->_rate = rate;
        return nil;
    }, ^BOOL(SGBlock block) {
        self.clock.rate = rate;
        self.audioRenderer.rate = rate;
        self.videoRenderer.rate = rate;
        return YES;
    });
}

- (CMTime)rate
{
    __block CMTime ret = kCMTimeZero;
    SGLockEXE00(self.lock, ^{
        ret = self->_rate;
    });
    return ret;
}

#pragma mark - Control

- (BOOL)play
{
    [SGActivity addTarget:self];
    return SGLockCondEXE10(self.lock, ^BOOL {
        return self->_status == SGPlayerStatusReady;
    }, ^SGBlock {
        self->_is_playing = 1;
        return [self setPlaybackState];
    });
}

- (BOOL)pause
{
    [SGActivity removeTarget:self];
    return SGLockCondEXE10(self.lock, ^BOOL {
        return self->_status == SGPlayerStatusReady;
    }, ^SGBlock {
        self->_is_playing = 0;
        return [self setPlaybackState];
    });
}

SGGet0Map(BOOL, seekable, self.currentItem);

- (BOOL)seekToTime:(CMTime)time result:(SGSeekResultBlock)result
{
    __block int32_t is_seeking = 0;
    BOOL ret = SGLockCondEXE10(self.lock, ^BOOL {
        return self->_status == SGPlayerStatusReady;
    }, ^SGBlock {
        self->_is_seeking += 1;
        is_seeking = self->_is_seeking;
        return [self setPlaybackState];
    });
    if (!ret) {
        return NO;
    }
    SGWeakify(self)
    return [self.currentItem seekToTime:time result:^(CMTime time, NSError * error) {
        SGStrongify(self)
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
        SGLockCondEXE10(self.lock, ^BOOL {
            return is_seeking == self->_is_seeking;
        }, ^SGBlock {
            self->_is_seeking = 0;
            if (!error) {
                self->_is_audio_finished = 0;
                self->_is_video_finished = 0;
                self->_is_current_time_valid = 0;
            }
            return [self setPlaybackState];
        });
    }];
}

#pragma mark - SGClockDelegate

- (void)clock:(SGClock *)clock didChcnageCurrentTime:(CMTime)currentTime
{
    SGLockEXE10(self.lock, ^SGBlock {
        return [self setCurrentTime:currentTime];
    });
}

#pragma mark - SGRenderableDelegate

- (void)renderable:(id <SGRenderable>)renderable didChangeState:(SGRenderableState)state
{
    NSAssert(state != SGRenderableStateFailed, @"Invaild renderer, %@", renderable);
}

- (void)renderable:(id <SGRenderable>)renderable didChangeCapacity:(SGCapacity *)capacity
{
    if (capacity.isEmpty) {
        SGLockCondEXE10(self.lock, ^BOOL {
            if (renderable == self.audioRenderer) {
                return self->_current_item.audioFinished;
            } else if (renderable == self.videoRenderer) {
                return self->_current_item.videoFinished;
            }
            return NO;
        }, ^SGBlock {
            if (renderable == self.audioRenderer) {
                self->_is_audio_finished = 1;
            } else if (renderable == self.videoRenderer) {
                self->_is_video_finished = 1;
            }
            return [self setPlaybackState];
        });
    }
}

- (__kindof SGFrame *)renderable:(id <SGRenderable>)renderable fetchFrame:(SGTimeReaderBlock)timeReader
{
    if (renderable == self.audioRenderer) {
        return [self.currentItem copyAudioFrame:timeReader];
    } else if (renderable == self.videoRenderer) {
        return [self.currentItem copyVideoFrame:timeReader];
    }
    return nil;
}

#pragma mark - SGPlayerItemDelegate

- (void)playerItem:(SGPlayerItem *)playerItem didChangeState:(SGPlayerItemState)state
{
    SGLockEXE10(self.lock, ^SGBlock {
        SGBlock b1 = ^{}, b2 = ^{}, b3 = ^{};
        switch (state) {
            case SGPlayerItemStateOpening: {
                b1 = [self setStatus:SGPlayerStatusPreparing];
            }
                break;
            case SGPlayerItemStateOpened: {
                b2 = [self setStatus:SGPlayerStatusReady];
                b3 = [self setLoadingState:SGLoadingStateStalled];
                b1 = ^{
                    [self.clock open];
                    if (playerItem.selectedAudioTrack) {
                        self->_is_audio_available = 1;
                        [self.audioRenderer open];
                    }
                    if (playerItem.selectedVideoTrack) {
                        self->_is_video_available = 1;
                        [self.videoRenderer open];
                    }
                    [playerItem start];
                };
            }
                break;
            case SGPlayerItemStateReading: {
                self->_is_audio_finished = 0;
                self->_is_video_finished = 0;
                b1 = [self setPlaybackState];
            }
                break;
            case SGPlayerItemStateFinished: {
                b1 = [self setLoadingState:SGLoadingStateFinished];
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
            b1(); b2(); b3();
        };
    });
}

- (void)playerItem:(SGPlayerItem *)playerItem didChangeCapacity:(SGCapacity *)capacity track:(SGTrack *)track
{
    BOOL should = NO;
    if (track.type == SGMediaTypeAudio &&
        !playerItem.audioFinished) {
        should = YES;
    } else if (track.type == SGMediaTypeVideo &&
               !playerItem.videoFinished &&
               (!playerItem.selectedAudioTrack || playerItem.audioFinished)) {
        should = YES;
    }
    if (should) {
        SGLockCondEXE10(self.lock, ^BOOL {
            return self->_is_current_time_valid;
        }, ^SGBlock {
            CMTime duration = capacity.duration;
            CMTime time = CMTimeAdd(self->_current_time, duration);
            SGBlock b1 = [self setLoadedTime:time loadedDuration:duration];
            SGBlock b2 = [self setLoadingState:(capacity.isEmpty || self->_loading_state == SGLoadingStateFinished) ? SGLoadingStateStalled : SGLoadingStatePlaybale];
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
    if (self.delegateQueue) {
        NSOperation * operation = [NSBlockOperation blockOperationWithBlock:^{
            block();
        }];
        [self.delegateQueue addOperation:operation];
    } else {
        block();
    }
}

@end
