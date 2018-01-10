//
//  SGAVPlayer.m
//  SGAVPlayer
//
//  Created by Single on 16/6/28.
//  Copyright © 2016年 single. All rights reserved.
//

#import "SGAVPlayer.h"
#import "SGAVPlayerView.h"
#import "SGPlayerCallback.h"
#import "SGAudioManager.h"
#import "SGPlayerMacro.h"
#import <AVFoundation/AVFoundation.h>


@interface SGAVPlayer ()

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, assign) SGPlayerState state;
@property (nonatomic, assign) NSTimeInterval loadedTime;
@property (nonatomic, copy) NSError * error;

@property (nonatomic, strong) AVPlayer * player;
@property (nonatomic, strong) AVPlayerItem * playerItem;
@property (nonatomic, strong) id playerTimeObserver;
@property (nonatomic, strong) SGAVPlayerView * playerView;

@property (nonatomic, assign) BOOL playing;
@property (nonatomic, assign) BOOL buffering;
@property (nonatomic, assign) BOOL seeking;

@property (nonatomic, assign) SGPlayerState stateBeforBuffering;
@property (nonatomic, assign) NSTimeInterval playableBufferInterval;
@property (nonatomic, assign) NSTimeInterval readyToPlayTime;

@property (nonatomic, assign) BOOL needAutoPlay;
@property (nonatomic, assign) NSTimeInterval lastForegroundTimeInterval;

@end


@implementation SGAVPlayer


- (instancetype)init
{
    if (self = [super init])
    {
        [self registerInterrupt];
        self.backgroundMode = SGPlayerBackgroundModeAutoPlayAndPause;
        self.playableBufferInterval = 2.f;
        self.playerView = [[SGAVPlayerView alloc] initWithFrame:CGRectZero];
    }
    return self;
}

- (void)dealloc
{
    [self removeInterrupt];
    [self clean];
}


- (void)replaceWithContentURL:(nullable NSURL *)contentURL
{
    [self clean];
    
    if (!contentURL) return;
    self.contentURL = contentURL;
    
    [self startBuffering];
    [self setupPlayer];
}


#pragma mark - Setup & Clean

- (void)setupPlayer
{
    // AVPlayerItem
    self.playerItem = [AVPlayerItem playerItemWithURL:self.contentURL];
    [self.playerItem addObserver:self forKeyPath:@"status" options:0 context:NULL];
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:NULL];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(avplayerItemDidPlayToEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    
    // AVPlayer
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    if (@available(iOS 10.0, *)) {
        self.player.automaticallyWaitsToMinimizeStalling = NO;
    }
    
    // AVPlayer Playback Time Observer
    SGWeakSelf
    self.playerTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        SGStrongSelf
        if (strongSelf.state == SGPlayerStatePlaying) {
            CGFloat current = CMTimeGetSeconds(time);
            CGFloat duration = strongSelf.duration;
            double percent = [strongSelf percentForTime:current duration:duration];
            [SGPlayerCallback callbackForPlaybackTime:strongSelf percent:percent current:current total:duration];
        }
    }];
}

- (void)cleanPlayer
{
    // AVPlayer Playback Time Observer
    if (self.playerTimeObserver)
    {
        [self.player removeTimeObserver:self.playerTimeObserver];
        self.playerTimeObserver = nil;
    }
    
    // AVPlayer
    if (self.player)
    {
        [self.player pause];
        [self.player cancelPendingPrerolls];
        [self.player replaceCurrentItemWithPlayerItem:nil];
        self.player = nil;
    }
    
    // AVPlayerItem
    if (self.playerItem)
    {
        [self.playerItem.asset cancelLoading];
        [self.playerItem cancelPendingSeeks];
        [self.playerItem removeObserver:self forKeyPath:@"status"];
        [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
        self.playerItem = nil;
    }
}

- (void)clean
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    [self cleanPlayer];
    
    [SGPlayerCallback callbackForPlaybackTime:self percent:0 current:0 total:0];
    [SGPlayerCallback callbackForLoadedTime:self percent:0 current:0 total:0];
    self.error = nil;
    self.contentURL = nil;
    self.state = SGPlayerStateNone;
    self.stateBeforBuffering = SGPlayerStateNone;
    self.seeking = NO;
    self.loadedTime = 0;
    self.readyToPlayTime = 0;
    self.buffering = NO;
    self.playing = NO;
    self.needAutoPlay = NO;
}


#pragma mark - Control

- (void)play
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    self.playing = YES;
    
    switch (self.state) {
        case SGPlayerStateFinished:
            [self.player seekToTime:kCMTimeZero];
            self.state = SGPlayerStatePlaying;
            break;
        case SGPlayerStateFailed:
            [self replaceWithContentURL:self.contentURL];
            break;
        case SGPlayerStateNone:
            self.state = SGPlayerStateBuffering;
            break;
        case SGPlayerStateSuspend:
            if (self.buffering) {
                self.state = SGPlayerStateBuffering;
            } else {
                self.state = SGPlayerStatePlaying;
            }
            break;
        case SGPlayerStateReadyToPlay:
            self.state = SGPlayerStatePlaying;
            break;
        default:
            break;
    }
    
    [self.player play];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        switch (self.state) {
            case SGPlayerStateBuffering:
            case SGPlayerStatePlaying:
            case SGPlayerStateReadyToPlay:
                [self.player play];
            default:
                break;
        }
    });
}

- (void)pause
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    [self.player pause];
    self.playing = NO;
    if (self.state == SGPlayerStateFailed) return;
    self.state = SGPlayerStateSuspend;
}

- (void)stop
{
    [self clean];
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(nullable void (^)(BOOL))completeHandler
{
    if (!self.seekEnable || self.playerItem.status != AVPlayerItemStatusReadyToPlay) {
        if (completeHandler) {
            completeHandler(NO);
        }
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.seeking = YES;
        [self startBuffering];
        SGWeakSelf
        [self.playerItem seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                SGStrongSelf
                strongSelf.seeking = NO;
                [strongSelf stopBuffering];
                [strongSelf resumeStateAfterBuffering];
                if (completeHandler) {
                    completeHandler(finished);
                }
                SGPlayerLog(@"SGAVPlayer seek success");
            });
        }];
    });
}


#pragma mark - Internal Functions

- (void)setState:(SGPlayerState)state
{
    if (_state != state) {
        SGPlayerState temp = _state;
        _state = state;
        switch (self.state) {
            case SGPlayerStateFinished:
                self.playing = NO;
                break;
            case SGPlayerStateFailed:
                self.playing = NO;
                break;
            default:
                break;
        }
        if (_state != SGPlayerStateFailed) {
            self.error = nil;
        }
        [SGPlayerCallback callbackForState:self current:_state previous:temp];
    }
}

- (NSTimeInterval)playbackTime
{
    CMTime currentTime = self.playerItem.currentTime;
    Boolean indefinite = CMTIME_IS_INDEFINITE(currentTime);
    Boolean invalid = CMTIME_IS_INVALID(currentTime);
    if (indefinite || invalid) {
        return 0;
    }
    return CMTimeGetSeconds(self.playerItem.currentTime);
}

- (NSTimeInterval)duration
{
    CMTime duration = self.playerItem.duration;
    Boolean indefinite = CMTIME_IS_INDEFINITE(duration);
    Boolean invalid = CMTIME_IS_INVALID(duration);
    if (indefinite || invalid) {
        return 0;
    }
    return CMTimeGetSeconds(self.playerItem.duration);;
}

- (void)setLoadedTime:(NSTimeInterval)loadedTime
{
    if (_loadedTime != loadedTime) {
        _loadedTime = loadedTime;
        CGFloat duration = self.duration;
        double percent = [self percentForTime:_loadedTime duration:duration];
        [SGPlayerCallback callbackForLoadedTime:self percent:percent current:_loadedTime total:duration];
    }
}

- (void)startBuffering
{
    if (self.playing) {
        [self.player pause];
    }
    self.buffering = YES;
    if (self.state != SGPlayerStateBuffering) {
        self.stateBeforBuffering = self.state;
    }
    self.state = SGPlayerStateBuffering;
}

- (void)stopBuffering
{
    self.buffering = NO;
}

- (void)resumeStateAfterBuffering
{
    if (self.playing) {
        [self.player play];
        self.state = SGPlayerStatePlaying;
    } else if (self.state == SGPlayerStateBuffering) {
        self.state = self.stateBeforBuffering;
    }
}

- (BOOL)playIfNeed
{
    if (self.playing) {
        [self.player play];
        self.state = SGPlayerStatePlaying;
        return YES;
    }
    return NO;
}

- (BOOL)seekEnable
{
    if (self.duration <= 0 || self.playerItem.status != AVPlayerItemStatusReadyToPlay) {
        return NO;
    }
    return YES;
}

- (double)percentForTime:(NSTimeInterval)time duration:(NSTimeInterval)duration
{
    double percent = 0;
    if (time > 0) {
        if (duration <= 0) {
            percent = 1;
        } else {
            percent = time / duration;
        }
    }
    return percent;
}

- (void)reloadPlayableTime
{
    if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
        CMTimeRange range = [self.playerItem.loadedTimeRanges.firstObject CMTimeRangeValue];
        if (CMTIMERANGE_IS_VALID(range)) {
            NSTimeInterval start = CMTimeGetSeconds(range.start);
            NSTimeInterval duration = CMTimeGetSeconds(range.duration);
            self.loadedTime = (start + duration);
        }
    } else {
        self.loadedTime = 0;
    }
}

- (void)avplayerItemDidPlayToEnd:(NSNotification *)notification
{
    self.state = SGPlayerStateFinished;
}

- (UIView *)view
{
    return self.playerView;
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (object == self.playerItem) {
        if ([keyPath isEqualToString:@"status"])
        {
            switch (self.playerItem.status) {
                case AVPlayerItemStatusUnknown:
                {
                    [self startBuffering];
                    SGPlayerLog(@"SGAVPlayer item status unknown");
                }
                    break;
                case AVPlayerItemStatusReadyToPlay:
                {
                    [self stopBuffering];
                    SGPlayerLog(@"SGAVPlayer item status ready to play");
                    self.readyToPlayTime = [NSDate date].timeIntervalSince1970;
                    if (![self playIfNeed]) {
                        switch (self.state) {
                            case SGPlayerStateSuspend:
                            case SGPlayerStateFinished:
                            case SGPlayerStateFailed:
                                break;
                            default:
                                self.state = SGPlayerStateReadyToPlay;
                                break;
                        }
                    }
                }
                    break;
                case AVPlayerItemStatusFailed:
                {
                    SGPlayerLog(@"SGAVPlayer item status failed");
                    [self stopBuffering];
                    self.readyToPlayTime = 0;
                    
                    NSError * error = nil;
                    if (self.playerItem.error) {
                        error = self.playerItem.error;
                    } else if (self.player.error) {
                        error = self.player.error;
                    } else {
                        error = [NSError errorWithDomain:@"AVPlayer playback error" code:-1 userInfo:nil];
                    }
                    self.error = error;
                    self.state = SGPlayerStateFailed;
                    [SGPlayerCallback callbackForError:self error:error];
                }
                    break;
            }
        }
        else if ([keyPath isEqualToString:@"playbackBufferEmpty"])
        {
            if (self.playerItem.playbackBufferEmpty) {
                [self startBuffering];
            }
        }
        else if ([keyPath isEqualToString:@"loadedTimeRanges"])
        {
            [self reloadPlayableTime];
            NSTimeInterval interval = self.loadedTime - self.playbackTime;
            NSTimeInterval residue = self.duration - self.playbackTime;
            if (residue <= -1.5) {
                residue = 2;
            }
            if (interval > self.playableBufferInterval) {
                [self stopBuffering];
                [self resumeStateAfterBuffering];
            } else if (interval < 0.3 && residue > 1.5) {
                [self startBuffering];
            }
        }
    }
}


#pragma mark - Interrupt

- (void)registerInterrupt
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    SGWeakSelf
    SGAudioManager * manager = [SGAudioManager manager];
    [manager setHandlerTarget:self interruption:^(id handlerTarget, SGAudioManager *audioManager, SGAudioManagerInterruptionType type, SGAudioManagerInterruptionOption option) {
        SGStrongSelf
        if (type == SGAudioManagerInterruptionTypeBegin) {
            switch (strongSelf.state) {
                case SGPlayerStatePlaying:
                case SGPlayerStateBuffering:
                {
                    // fix : maybe receive interruption notification when enter foreground.
                    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
                    if (timeInterval - strongSelf.lastForegroundTimeInterval > 1.5) {
                        [strongSelf pause];
                    }
                }
                    break;
                default:
                    break;
            }
        }
    } routeChange:^(id handlerTarget, SGAudioManager *audioManager, SGAudioManagerRouteChangeReason reason) {
        SGStrongSelf
        if (reason == SGAudioManagerRouteChangeReasonOldDeviceUnavailable) {
            switch (strongSelf.state) {
                case SGPlayerStatePlaying:
                case SGPlayerStateBuffering:
                {
                    [strongSelf pause];
                }
                    break;
                default:
                    break;
            }
        }
    }];
}

- (void)removeInterrupt
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[SGAudioManager manager] removeHandlerTarget:self];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    switch (self.backgroundMode) {
        case SGPlayerBackgroundModeNothing:
        case SGPlayerBackgroundModeContinue:
            break;
        case SGPlayerBackgroundModeAutoPlayAndPause:
        {
            switch (self.state) {
                case SGPlayerStatePlaying:
                case SGPlayerStateBuffering:
                {
                    self.needAutoPlay = YES;
                    [self pause];
                }
                    break;
                default:
                    break;
            }
        }
            break;
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    switch (self.backgroundMode) {
        case SGPlayerBackgroundModeNothing:
        case SGPlayerBackgroundModeContinue:
            break;
        case SGPlayerBackgroundModeAutoPlayAndPause:
        {
            switch (self.state) {
                case SGPlayerStateSuspend:
                {
                    if (self.needAutoPlay) {
                        self.needAutoPlay = NO;
                        [self play];
                        self.lastForegroundTimeInterval = [NSDate date].timeIntervalSince1970;
                    }
                }
                    break;
                default:
                    break;
            }
        }
            break;
    }
}


@end

