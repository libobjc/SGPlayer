//
//  SGPlayer.m
//  SGPlayer
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "SGPlayerItem+Internal.h"
#import "SGRenderer+Internal.h"
#import "SGActivity.h"
#import "SGMacro.h"
#import "SGLock.h"

#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
#import <UIKit/UIKit.h>
#endif

NSString * const SGPlayerTimeInfoUserInfoKey   = @"SGPlayerTimeInfoUserInfoKey";
NSString * const SGPlayerStateInfoUserInfoKey  = @"SGPlayerStateInfoUserInfoKey";
NSString * const SGPlayerInfoActionUserInfoKey = @"SGPlayerInfoActionUserInfoKey";
NSNotificationName const SGPlayerDidChangeInfosNotification = @"SGPlayerDidChangeInfosNotification";

@interface SGPlayer () <SGClockDelegate, SGRenderableDelegate, SGPlayerItemDelegate>

{
    struct {
        BOOL playing;
        BOOL audioFinished;
        BOOL videoFinished;
        BOOL audioAvailable;
        BOOL videoAvailable;
        NSError *error;
        NSUInteger seekingIndex;
        SGTimeInfo timeInfo;
        SGStateInfo stateInfo;
        SGInfoAction additionalAction;
        NSTimeInterval lastNotificationTime;
    } _flags;
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) SGClock *clock;
@property (nonatomic, strong, readonly) SGPlayerItem *currentItem;
@property (nonatomic, strong, readonly) SGAudioRenderer *audioRenderer;
@property (nonatomic, strong, readonly) SGVideoRenderer *videoRenderer;

@end

@implementation SGPlayer

@synthesize rate = _rate;
@synthesize clock = _clock;
@synthesize currentItem = _currentItem;
@synthesize audioRenderer = _audioRenderer;
@synthesize videoRenderer = _videoRenderer;

- (instancetype)init
{
    if (self = [super init]) {
        [self stop];
        self->_options = [SGOptions sharedOptions].copy;
        self->_rate = 1.0;
        self->_lock = [[NSLock alloc] init];
        self->_clock = [[SGClock alloc] init];
        self->_clock.delegate = self;
        self->_audioRenderer = [[SGAudioRenderer alloc] initWithClock:self->_clock];
        self->_audioRenderer.delegate = self;
        self->_videoRenderer = [[SGVideoRenderer alloc] initWithClock:self->_clock];
        self->_videoRenderer.delegate = self;
        self->_actionMask = SGInfoActionNone;
        self->_minimumTimeInfoInterval = 1.0;
        self->_notificationQueue = [NSOperationQueue mainQueue];
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
        self->_pausesWhenInterrupted = YES;
        self->_pausesWhenEnteredBackground = NO;
        self->_pausesWhenEnteredBackgroundIfNoAudioTrack = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptionHandler:) name:AVAudioSessionInterruptionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackgroundHandler:) name:UIApplicationDidEnterBackgroundNotification object:nil];
#endif
    }
    return self;
}

- (void)dealloc
{
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
    [SGActivity removeTarget:self];
    [self->_currentItem close];
    [self->_clock close];
    [self->_audioRenderer close];
    [self->_videoRenderer close];
}

#pragma mark - Info

- (SGBlock)setPlayerState:(SGPlayerState)state action:(SGInfoAction *)action
{
    if (self->_flags.stateInfo.player == state) {
        return ^{};
    }
    *action |= SGInfoActionStatePlayer;
    self->_flags.stateInfo.player = state;
    return ^{
        if (state == SGPlayerStateReady) {
            if (self->_readyHandler) {
                self->_readyHandler(self);
            }
            if (self->_wantsToPlay) {
                [self play];
            }
        }
    };
}

- (SGBlock)setPlaybackState:(SGInfoAction *)action
{
    SGPlaybackState state = 0;
    if (self->_flags.playing) {
        state |= SGPlaybackStatePlaying;
    }
    if (self->_flags.seekingIndex > 0) {
        state |= SGPlaybackStateSeeking;
    }
    if (self->_flags.stateInfo.player == SGPlayerStateReady &&
        (!self->_flags.audioAvailable || self->_flags.audioFinished) &&
        (!self->_flags.videoAvailable || self->_flags.videoFinished)) {
        state |= SGPlaybackStateFinished;
    }
    if (self->_flags.stateInfo.playback == state) {
        return ^{};
    }
    *action |= SGInfoActionStatePlayback;
    self->_flags.stateInfo.playback = state;
    SGBlock b1 = ^{};
    if (state & SGPlaybackStateFinished) {
        [self setCachedDuration:kCMTimeZero action:action];
        [self setPlaybackTime:self->_flags.timeInfo.duration action:action];
    }
    if (state & SGPlaybackStateFinished) {
        b1 = ^{
            [self->_clock pause];
            [self->_audioRenderer finish];
            [self->_videoRenderer finish];
        };
    } else if (state & SGPlaybackStatePlaying) {
        b1 = ^{
            [self->_clock resume];
            [self->_audioRenderer resume];
            [self->_videoRenderer resume];
        };
    } else {
        b1 = ^{
            [self->_clock pause];
            [self->_audioRenderer pause];
            [self->_videoRenderer pause];
        };
    }
    return b1;
}

- (SGBlock)setLoadingState:(SGLoadingState)state action:(SGInfoAction *)action
{
    if (self->_flags.stateInfo.loading == state) {
        return ^{};
    }
    *action |= SGInfoActionStateLoading;
    self->_flags.stateInfo.loading = state;
    return ^{};
}

- (void)setPlaybackTime:(CMTime)time action:(SGInfoAction *)action
{
    if (CMTimeCompare(self->_flags.timeInfo.playback, time) == 0) {
        return;
    }
    *action |= SGInfoActionTimePlayback;
    self->_flags.timeInfo.playback = time;
}

- (void)setDuration:(CMTime)duration action:(SGInfoAction *)action
{
    if (CMTimeCompare(self->_flags.timeInfo.duration, duration) == 0) {
        return;
    }
    *action |= SGInfoActionTimeDuration;
    self->_flags.timeInfo.duration = duration;
}

- (void)setCachedDuration:(CMTime)duration action:(SGInfoAction *)action
{
    if (CMTimeCompare(self->_flags.timeInfo.cached, duration) == 0) {
        return;
    }
    *action |= SGInfoActionTimeCached;
    self->_flags.timeInfo.cached = duration;
}

#pragma mark - Setter & Getter

- (NSError *)error
{
    NSError *error;
    [self stateInfo:nil timeInfo:nil error:&error];
    return error;
}

- (SGTimeInfo)timeInfo
{
    SGTimeInfo timeInfo;
    [self stateInfo:nil timeInfo:&timeInfo error:nil];
    return timeInfo;
}

- (SGStateInfo)sstateInfo
{
    SGStateInfo stateInfo;
    [self stateInfo:&stateInfo timeInfo:nil error:nil];
    return stateInfo;
}

- (BOOL)stateInfo:(SGStateInfo *)stateInfo timeInfo:(SGTimeInfo *)timeInfo error:(NSError **)error
{
    __block NSError *err = nil;
    SGLockEXE00(self->_lock, ^{
        if (stateInfo) {
            *stateInfo = self->_flags.stateInfo;
        }
        if (timeInfo) {
            *timeInfo = self->_flags.timeInfo;
        }
        err = self->_flags.error;
    });
    if (error) {
        *error = err;
    }
    return YES;
}

- (SGPlayerItem *)currentItem
{
    __block SGPlayerItem *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = self->_currentItem;
    });
    return ret;
}

- (void)setRate:(Float64)rate
{
    SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_rate != rate;
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

- (Float64)rate
{
    __block Float64 ret = 1.0;
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
        self->_currentItem.demuxerOptions = self->_options.demuxer;
        self->_currentItem.decoderOptions = self->_options.decoder;
        self->_currentItem.processorOptions = self->_options.processor;
        return nil;
    }, ^BOOL(SGBlock block) {
        return [item open];
    });
}

- (BOOL)stop
{
    [SGActivity removeTarget:self];
    return SGLockEXE10(self->_lock, ^SGBlock {
        SGPlayerItem *currentItem = self->_currentItem;
        self->_currentItem = nil;
        self->_flags.error = nil;
        self->_flags.playing = NO;
        self->_flags.seekingIndex = 0;
        self->_flags.audioFinished = NO;
        self->_flags.videoFinished = NO;
        self->_flags.audioAvailable = NO;
        self->_flags.videoAvailable = NO;
        self->_flags.additionalAction = SGInfoActionNone;
        self->_flags.lastNotificationTime = 0.0;
        self->_flags.timeInfo.cached = kCMTimeInvalid;
        self->_flags.timeInfo.playback = kCMTimeInvalid;
        self->_flags.timeInfo.duration = kCMTimeInvalid;
        self->_flags.stateInfo.player = SGPlayerStateNone;
        self->_flags.stateInfo.loading = SGLoadingStateNone;
        self->_flags.stateInfo.playback = SGPlaybackStateNone;
        SGInfoAction action = SGInfoActionNone;
        SGBlock b1 = [self setPlayerState:SGPlayerStateNone action:&action];
        SGBlock b2 = [self setPlaybackState:&action];
        SGBlock b3 = [self setLoadingState:SGLoadingStateNone action:&action];
        SGBlock b4 = [self infoCallback:action];
        return ^{
            [currentItem close];
            [self->_clock close];
            [self->_audioRenderer close];
            [self->_videoRenderer close];
            b1(); b2(); b3(); b4();
        };
    });
}

#pragma mark - Playback

- (BOOL)play
{
    self->_wantsToPlay = YES;
    [SGActivity addTarget:self];
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.stateInfo.player == SGPlayerStateReady;
    }, ^SGBlock {
        self->_flags.playing = YES;
        SGInfoAction action = SGInfoActionNone;
        SGBlock b1 = [self setPlaybackState:&action];
        SGBlock b2 = [self infoCallback:action];
        return ^{b1(); b2();};
    });
}

- (BOOL)pause
{
    self->_wantsToPlay = NO;
    [SGActivity removeTarget:self];
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.stateInfo.player == SGPlayerStateReady;
    }, ^SGBlock {
        self->_flags.playing = NO;
        SGInfoAction action = SGInfoActionNone;
        SGBlock b1 = [self setPlaybackState:&action];
        SGBlock b2 = [self infoCallback:action];
        return ^{b1(); b2();};
    });
}

-  (BOOL)seekable
{
    SGPlayerItem *currentItem = [self currentItem];
    return [currentItem seekable];
}

- (BOOL)seekToTime:(CMTime)time
{
    return [self seekToTime:time result:nil];
}

- (BOOL)seekToTime:(CMTime)time result:(SGSeekResult)result
{
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid result:result];
}

- (BOOL)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter result:(SGSeekResult)result
{
    __block NSUInteger seekingCount = 0;
    __block SGPlayerItem *currentItem = nil;
    BOOL ret = SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.stateInfo.player == SGPlayerStateReady;
    }, ^SGBlock {
        self->_flags.seekingIndex += 1;
        currentItem = self->_currentItem;
        seekingCount = self->_flags.seekingIndex;
        SGInfoAction action = SGInfoActionNone;
        SGBlock b1 = [self setPlaybackState:&action];
        SGBlock b2 = [self infoCallback:action];
        return ^{b1(); b2();};
    });
    if (!ret) {
        return NO;
    }
    SGWeakify(self)
    return [currentItem seekToTime:time toleranceBefor:toleranceBefor toleranceAfter:toleranceAfter result:^(CMTime time, NSError *error) {
        SGStrongify(self)
        SGLockCondEXE11(self->_lock, ^BOOL {
            return seekingCount == self->_flags.seekingIndex;
        }, ^SGBlock {
            SGBlock b1 = ^{};
            self->_flags.seekingIndex = 0;
            if (!error) {
                self->_flags.audioFinished = NO;
                self->_flags.videoFinished = NO;
                self->_flags.lastNotificationTime = 0.0;
                b1 = ^{
                    [self->_clock flush];
                    [self->_audioRenderer flush];
                    [self->_videoRenderer flush];
                };
            }
            SGInfoAction action = SGInfoActionNone;
            SGBlock b2 = [self setPlaybackState:&action];
            SGBlock b3 = [self infoCallback:action];
            return ^{b1(); b2(); b3();};
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

- (void)clock:(SGClock *)clock didChangeCurrentTime:(CMTime)currentTime
{
    SGLockEXE10(self->_lock, ^SGBlock {
        SGInfoAction action = SGInfoActionNone;
        [self setPlaybackTime:currentTime action:&action];
        return [self infoCallback:action];
    });
}

#pragma mark - SGRenderableDelegate

- (void)renderable:(id<SGRenderable>)renderable didChangeState:(SGRenderableState)state
{
    NSAssert(state != SGRenderableStateFailed, @"Invaild renderer, %@", renderable);
}

- (void)renderable:(id<SGRenderable>)renderable didChangeCapacity:(SGCapacity)capacity
{
    if (SGCapacityIsEmpty(capacity)) {
        SGLockEXE10(self->_lock, ^SGBlock {
            if (SGCapacityIsEmpty(self->_audioRenderer.capacity) && [self->_currentItem isFinished:SGMediaTypeAudio]) {
                self->_flags.audioFinished = YES;
            }
            if (SGCapacityIsEmpty(self->_videoRenderer.capacity) && [self->_currentItem isFinished:SGMediaTypeVideo]) {
                self->_flags.videoFinished = YES;
            }
            SGInfoAction action = SGInfoActionNone;
            SGBlock b1 = [self setPlaybackState:&action];
            SGBlock b2 = [self infoCallback:action];
            return ^{b1(); b2();};
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
        SGInfoAction action = SGInfoActionNone;
        SGBlock b1 = ^{}, b2 = ^{}, b3 = ^{}, b4 = ^{};
        switch (state) {
            case SGPlayerItemStateOpening: {
                b1 = [self setPlayerState:SGPlayerStatePreparing action:&action];
            }
                break;
            case SGPlayerItemStateOpened: {
                CMTime duration = self->_currentItem.duration;
                [self setDuration:duration action:&action];
                [self setPlaybackTime:kCMTimeZero action:&action];
                [self setCachedDuration:kCMTimeZero action:&action];
                b1 = ^{
                    [self->_clock open];
                    if ([playerItem isAvailable:SGMediaTypeAudio]) {
                        self->_flags.audioAvailable = YES;
                        [self->_audioRenderer open];
                    }
                    if ([playerItem isAvailable:SGMediaTypeVideo]) {
                        self->_flags.videoAvailable = YES;
                        [self->_videoRenderer open];
                    }
                };
                b2 = [self setPlayerState:SGPlayerStateReady action:&action];
                b3 = [self setLoadingState:SGLoadingStateStalled action:&action];
                b4 = ^{
                    [playerItem start];
                };
            }
                break;
            case SGPlayerItemStateReading: {
                b1 = [self setPlaybackState:&action];
            }
                break;
            case SGPlayerItemStateFinished: {
                b1 = [self setLoadingState:SGLoadingStateFinished action:&action];
                if (SGCapacityIsEmpty(self->_audioRenderer.capacity)) {
                    self->_flags.audioFinished = YES;
                }
                if (SGCapacityIsEmpty(self->_videoRenderer.capacity)) {
                    self->_flags.videoFinished = YES;
                }
                b2 = [self setPlaybackState:&action];
            }
                break;
            case SGPlayerItemStateFailed: {
                self->_flags.error = [playerItem.error copy];
                b1 = [self setPlayerState:SGPlayerStateFailed action:&action];
            }
                break;
            default:
                break;
        }
        SGBlock b5 = [self infoCallback:action];
        return ^{b1(); b2(); b3(); b4(); b5();};
    });
}

- (void)playerItem:(SGPlayerItem *)playerItem didChangeCapacity:(SGCapacity)capacity type:(SGMediaType)type
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
        SGLockEXE10(self->_lock, ^SGBlock {
            SGInfoAction action = SGInfoActionNone;
            CMTime duration = capacity.duration;
            SGLoadingState loadingState = (SGCapacityIsEmpty(capacity) || self->_flags.stateInfo.loading == SGLoadingStateFinished) ? SGLoadingStateStalled : SGLoadingStatePlaybale;
            [self setCachedDuration:duration action:&action];
            SGBlock b1 = [self setLoadingState:loadingState action:&action];
            SGBlock b2 = [self infoCallback:action];
            return ^{b1(); b2();};
        });
    }
}

#pragma mark - Notification

- (SGBlock)infoCallback:(SGInfoAction)action
{
    action &= ~self->_actionMask;
    BOOL needed = NO;
    if (action & SGInfoActionState) {
        needed = YES;
    } else if (action & SGInfoActionTime) {
        NSTimeInterval currentTime = CACurrentMediaTime();
        NSTimeInterval interval = currentTime - self->_flags.lastNotificationTime;
        if (self->_flags.playing == NO ||
            interval >= self->_minimumTimeInfoInterval) {
            needed = YES;
            self->_flags.lastNotificationTime = currentTime;
        } else {
            self->_flags.additionalAction |= (action & SGInfoActionTime);
        }
    }
    if (!needed) {
        return ^{};
    }
    action |= self->_flags.additionalAction;
    self->_flags.additionalAction = SGInfoActionNone;
    NSValue *timeInfo = [NSValue value:&self->_flags.timeInfo withObjCType:@encode(SGTimeInfo)];
    NSValue *stateInfo = [NSValue value:&self->_flags.stateInfo withObjCType:@encode(SGStateInfo)];
    id userInfo = @{SGPlayerTimeInfoUserInfoKey : timeInfo,
                    SGPlayerStateInfoUserInfoKey : stateInfo,
                    SGPlayerInfoActionUserInfoKey : @(action)};
    return ^{
        [self callback:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SGPlayerDidChangeInfosNotification
                                                                object:self
                                                              userInfo:userInfo];
        }];
    };
}

- (void)callback:(void (^)(void))block
{
    if (!block) {
        return;
    }
    if (self->_notificationQueue) {
        [self->_notificationQueue addOperation:[NSBlockOperation blockOperationWithBlock:block]];
    } else {
        block();
    }
}

+ (SGTimeInfo)timeInfoFromUserInfo:(NSDictionary *)userInfo
{
    SGTimeInfo info;
    NSValue *value = userInfo[SGPlayerTimeInfoUserInfoKey];
    [value getValue:&info];
    return info;
}

+ (SGStateInfo)stateInfoFromUserInfo:(NSDictionary *)userInfo
{
    SGStateInfo info;
    NSValue *value = userInfo[SGPlayerStateInfoUserInfoKey];
    [value getValue:&info];
    return info;
}

+ (SGInfoAction)infoActionFromUserInfo:(NSDictionary *)userInfo
{
    return [userInfo[SGPlayerInfoActionUserInfoKey] unsignedIntegerValue];
}

#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
- (void)interruptionHandler:(NSNotification *)notification
{
    if (self->_pausesWhenInterrupted == YES) {
        AVAudioSessionInterruptionType type = [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
        if (type == AVAudioSessionInterruptionTypeBegan) {
            [self pause];
        }
    }
}

- (void)enterBackgroundHandler:(NSNotification *)notification
{
    if (self->_pausesWhenEnteredBackground) {
        [self pause];
    } else if (self->_pausesWhenEnteredBackgroundIfNoAudioTrack) {
        SGLockCondEXE11(self->_lock, ^BOOL {
            return self->_flags.audioAvailable == NO && self->_flags.videoAvailable == YES;
        }, nil, ^BOOL(SGBlock block) {
            return [self pause];
        });
    }
}
#endif

@end
