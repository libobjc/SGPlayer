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

NSString * const SGPlayerNotificationName_StateInfo   = @"SGPlayerNotificationName_StateInfo";
NSString * const SGPlayerNotificationName_TimingInfo  = @"SGPlayerNotificationName_TimingInfo";
NSString * const SGPlayerNotificationUserInfoKey_Info = @"SGPlayerNotificationUserInfoKey_Info";

@interface SGPlayer () <SGClockDelegate, SGRenderableDelegate, SGPlayerItemDelegate>

{
    struct {
        BOOL playing;
        BOOL audioFinished;
        BOOL videoFinished;
        BOOL audioAvailable;
        BOOL videoAvailable;
        BOOL currentTimeValid;
        NSError *error;
        UInt32 seekingCount;
        SGStateInfo stateInfo;
        SGTimingInfo timingInfo;
    } _flags;
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) SGClock *clock;
@property (nonatomic, strong, readonly) NSCondition *wakeup;
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
        self->_rate = CMTimeMake(1, 1);
        self->_notificationQueue = [NSOperationQueue mainQueue];
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

#pragma mark - Info

- (SGBlock)setPlayerState:(SGPlayerState)state success:(BOOL *)success
{
    if (self->_flags.stateInfo.player == state) {
        return ^{};
    }
    *success |= YES;
    self->_flags.stateInfo.player = state;
    return ^{
        [self->_wakeup lock];
        [self->_wakeup broadcast];
        [self->_wakeup unlock];
    };
}

- (SGBlock)setPlaybackState:(BOOL *)success
{
    SGPlaybackState state = 0;
    if (self->_flags.playing) {
        state |= SGPlaybackStatePlaying;
    }
    if (self->_flags.seekingCount > 0) {
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
    *success |= YES;
    self->_flags.stateInfo.playback = state;
    SGBlock b1 = ^{}, b2 = ^{};
    if (state & SGPlaybackStateFinished) {
        BOOL success = NO;
        [self setCachedDuration:kCMTimeZero success:&success];
        [self setPlaybackTime:self->_flags.timingInfo.duration success:&success];
        b1 = [self getTimingCallback:success];
    }
    if (state & SGPlaybackStateFinished) {
        b2 = ^{
            [self->_audioRenderer finish];
            [self->_videoRenderer finish];
        };
    } else if (state & SGPlaybackStatePlaying) {
        b2 = ^{
            [self->_clock resume];
            [self->_audioRenderer resume];
            [self->_videoRenderer resume];
        };
    } else {
        b2 = ^{
            [self->_clock pause];
            [self->_audioRenderer pause];
            [self->_videoRenderer pause];
        };
    }
    return ^{b1(); b2();};
}

- (SGBlock)setLoadingState:(SGLoadingState)state success:(BOOL *)success
{
    if (self->_flags.stateInfo.loading == state) {
        return ^{};
    }
    *success |= YES;
    self->_flags.stateInfo.loading = state;
    return ^{};
}

- (void)setPlaybackTime:(CMTime)time success:(BOOL *)success
{
    if (CMTimeCompare(self->_flags.timingInfo.playback, time) == 0) {
        return;
    }
    *success |= YES;
    self->_flags.currentTimeValid = YES;
    self->_flags.timingInfo.playback = time;
}

- (void)setDuration:(CMTime)duration success:(BOOL *)success
{
    if (CMTimeCompare(self->_flags.timingInfo.duration, duration) == 0) {
        return;
    }
    *success |= YES;
    self->_flags.timingInfo.duration = duration;
}

- (void)setCachedDuration:(CMTime)duration success:(BOOL *)success
{
    if (CMTimeCompare(self->_flags.timingInfo.cached, duration) == 0) {
        return;
    }
    *success |= YES;
    self->_flags.timingInfo.cached = duration;
}

#pragma mark - Setter & Getter

- (NSError *)error
{
    __block NSError *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_flags.error copy];
    });
    return ret;
}

- (SGStateInfo)stateInfo
{
    __block SGStateInfo ret;
    SGLockEXE00(self->_lock, ^{
        ret = self->_flags.stateInfo;
    });
    return ret;
}

- (SGTimingInfo)timingInfo
{
    __block SGTimingInfo ret;
    SGLockEXE00(self->_lock, ^{
        ret = self->_flags.timingInfo;
    });
    return ret;
}

- (BOOL)error:(NSError **)error stateInfo:(SGStateInfo *)stateInfo timingInfo:(SGTimingInfo *)timingInfo
{
    __block NSError *err = nil;
    SGLockEXE00(self->_lock, ^{
        err = self->_flags.error;
        *stateInfo = self->_flags.stateInfo;
        *timingInfo = self->_flags.timingInfo;
    });
    *error = err;
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
            return self->_flags.stateInfo.player == SGPlayerStatePreparing;
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
        self->_flags.playing = NO;
        self->_flags.seekingCount = 0;
        self->_flags.audioFinished = NO;
        self->_flags.videoFinished = NO;
        self->_flags.audioAvailable = NO;
        self->_flags.videoAvailable = NO;
        self->_flags.currentTimeValid = NO;
        self->_flags.timingInfo.cached = kCMTimeInvalid;
        self->_flags.timingInfo.playback = kCMTimeInvalid;
        self->_flags.timingInfo.duration = kCMTimeInvalid;
        self->_flags.stateInfo.player = SGPlayerStateNone;
        self->_flags.stateInfo.loading = SGLoadingStateNone;
        self->_flags.stateInfo.playback = SGPlaybackStateNone;
        self->_flags.error = nil;
        self->_currentItem = nil;
        BOOL success = NO;
        SGBlock b1 = [self setPlayerState:SGPlayerStateNone success:&success];
        SGBlock b2 = [self setPlaybackState:&success];
        SGBlock b3 = [self setLoadingState:SGLoadingStateNone success:&success];
        SGBlock b4 = [self getStateCallback:success];
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
    [SGActivity addTarget:self];
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.stateInfo.player == SGPlayerStateReady;
    }, ^SGBlock {
        self->_flags.playing = YES;
        BOOL success = NO;
        SGBlock b1 = [self setPlaybackState:&success];
        SGBlock b2 = [self getStateCallback:success];
        return ^{b1(); b2();};
    });
}

- (BOOL)pause
{
    [SGActivity removeTarget:self];
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.stateInfo.player == SGPlayerStateReady;
    }, ^SGBlock {
        self->_flags.playing = NO;
        BOOL success = NO;
        SGBlock b1 = [self setPlaybackState:&success];
        SGBlock b2 = [self getStateCallback:success];
        return ^{b1(); b2();};
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
        return self->_flags.stateInfo.player == SGPlayerStateReady;
    }, ^SGBlock {
        self->_flags.seekingCount += 1;
        currentItem = self->_currentItem;
        seekingCount = self->_flags.seekingCount;
        BOOL success = NO;
        SGBlock b1 = [self setPlaybackState:&success];
        SGBlock b2 = [self getStateCallback:success];
        return ^{b1(); b2();};
    });
    if (!ret) {
        return NO;
    }
    SGWeakify(self)
    return [currentItem seekToTime:time result:^(CMTime time, NSError *error) {
        SGStrongify(self)
        SGLockCondEXE11(self->_lock, ^BOOL {
            return seekingCount == self->_flags.seekingCount;
        }, ^SGBlock {
            SGBlock b1 = ^{};
            self->_flags.seekingCount = 0;
            if (!error) {
                self->_flags.audioFinished = NO;
                self->_flags.videoFinished = NO;
                self->_flags.currentTimeValid = NO;
                b1 = ^{
                    [self->_clock flush];
                    [self->_audioRenderer flush];
                    [self->_videoRenderer flush];
                };
            }
            BOOL success = NO;
            SGBlock b2 = [self setPlaybackState:&success];
            SGBlock b3 = [self getStateCallback:success];
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

- (void)clock:(SGClock *)clock didChcnageCurrentTime:(CMTime)currentTime
{
    SGLockEXE10(self->_lock, ^SGBlock {
        BOOL success = NO;
        [self setPlaybackTime:currentTime success:&success];
        return [self getTimingCallback:success];
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
            BOOL success = NO;
            SGBlock b1 = [self setPlaybackState:&success];
            SGBlock b2 = [self getStateCallback:success];
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
        BOOL success_state = NO;
        BOOL success_timing = NO;
        SGBlock b1 = ^{}, b2 = ^{}, b3 = ^{};
        switch (state) {
            case SGPlayerItemStateOpening: {
                b1 = [self setPlayerState:SGPlayerStatePreparing success:&success_state];
            }
                break;
            case SGPlayerItemStateOpened: {
                b2 = [self setPlayerState:SGPlayerStateReady success:&success_state];
                b3 = [self setLoadingState:SGLoadingStateStalled success:&success_state];
                CMTime duration = self->_currentItem.duration;
                [self setDuration:duration success:&success_timing];
                [self setPlaybackTime:kCMTimeZero success:&success_timing];
                [self setCachedDuration:kCMTimeZero success:&success_timing];
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
                    [playerItem start];
                };
            }
                break;
            case SGPlayerItemStateReading: {
                b1 = [self setPlaybackState:&success_state];
            }
                break;
            case SGPlayerItemStateFinished: {
                b1 = [self setLoadingState:SGLoadingStateFinished success:&success_state];
                if (SGCapacityIsEmpty(self->_audioRenderer.capacity)) {
                    self->_flags.audioFinished = YES;
                }
                if (SGCapacityIsEmpty(self->_videoRenderer.capacity)) {
                    self->_flags.videoFinished = YES;
                }
                b2 = [self setPlaybackState:&success_state];
            }
                break;
            case SGPlayerItemStateFailed: {
                self->_flags.error = [playerItem.error copy];
                b1 = [self setPlayerState:SGPlayerStateFailed success:&success_state];
            }
                break;
            default:
                break;
        }
        SGBlock b4 = [self getTimingCallback:success_timing];
        SGBlock b5 = [self getStateCallback:success_state];
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
        SGLockCondEXE10(self->_lock, ^BOOL {
            return self->_flags.currentTimeValid;
        }, ^SGBlock {
            BOOL success_state = NO;
            BOOL success_timing = NO;
            CMTime duration = capacity.duration;
            SGLoadingState loadingState = (SGCapacityIsEmpty(capacity) || self->_flags.stateInfo.loading == SGLoadingStateFinished) ? SGLoadingStateStalled : SGLoadingStatePlaybale;
            [self setCachedDuration:duration success:&success_timing];
            SGBlock b1 = [self getTimingCallback:success_timing];
            SGBlock b2 = [self setLoadingState:loadingState success:&success_state];
            SGBlock b3 = [self getStateCallback:success_state];
            return ^{b1(); b2(); b3();};
        });
    }
}

#pragma mark - Notification

- (SGBlock)getStateCallback:(BOOL)success
{
    if (!success) {
        return ^{};
    }
    NSValue *value = [NSValue value:&self->_flags.stateInfo withObjCType:@encode(SGStateInfo)];
    id name = SGPlayerNotificationName_StateInfo;
    id userInfo = @{SGPlayerNotificationUserInfoKey_Info : value};
    return ^{
        [self callback:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
        }];
    };
}

- (SGBlock)getTimingCallback:(BOOL)success
{
    if (!success) {
        return ^{};
    }
    NSValue *value = [NSValue value:&self->_flags.timingInfo withObjCType:@encode(SGTimingInfo)];
    id name = SGPlayerNotificationName_TimingInfo;
    id userInfo = @{SGPlayerNotificationUserInfoKey_Info : value};
    return ^{
        [self callback:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
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

+ (SGStateInfo)userInfoToStateInfo:(NSDictionary *)userInfo
{
    SGStateInfo info;
    NSValue *value = userInfo[SGPlayerNotificationUserInfoKey_Info];
    [value getValue:&info];
    return info;
}

+ (SGTimingInfo)userInfoToTimingInfo:(NSDictionary *)userInfo
{
    SGTimingInfo info;
    NSValue *value = userInfo[SGPlayerNotificationUserInfoKey_Info];
    [value getValue:&info];
    return info;
}

@end
