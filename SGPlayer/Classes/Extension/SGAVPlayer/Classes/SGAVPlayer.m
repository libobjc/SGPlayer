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
#import "SGPlayerActivity.h"
#import "SGAudioManager.h"
#import "SGPlayerMacro.h"
#import <AVFoundation/AVFoundation.h>


@interface SGAVPlayer ()

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, assign) SGPlayerPlaybackState playbackState;
@property (nonatomic, assign) SGPlayerPlaybackState playbackStateBeforSeeking;
@property (nonatomic, assign) SGPlayerLoadState loadState;
@property (nonatomic, assign) NSTimeInterval loadedTime;
@property (nonatomic, copy) NSError * error;

@property (nonatomic, strong) AVPlayer * player;
@property (nonatomic, strong) AVPlayerItem * playerItem;
@property (nonatomic, strong) id playerTimeObserver;
@property (nonatomic, strong) SGAVPlayerView * playerView;

@property (nonatomic, assign) BOOL shouldAutoPlay;
@property (nonatomic, assign) NSTimeInterval lastForegroundTimeInterval;

@end


@implementation SGAVPlayer


- (instancetype)init
{
    if (self = [super init])
    {
        [self registerInterrupt];
        self.backgroundMode = SGPlayerBackgroundModeAutoPlayAndPause;
        self.minimumPlayableDuration = 2.f;
        self.playerView = [[SGAVPlayerView alloc] initWithFrame:CGRectZero];
    }
    return self;
}

- (void)dealloc
{
    [SGPlayerActivity resignActive:self];
    [self cleanPlayer];
    [self removeInterrupt];
}


- (void)replaceWithContentURL:(nullable NSURL *)contentURL
{
    [self clear];
    if (contentURL == nil) {
        return;
    }
    self.contentURL = contentURL;
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
                                             selector:@selector(playerItemDidPlayToEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    
    // AVPlayer
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerView.playerLayer.player = self.player;
    if (@available(iOS 10.0, *)) {
        self.player.automaticallyWaitsToMinimizeStalling = NO;
    }
    
    // AVPlayer Playback Time Observer
    SGWeakSelf
    self.playerTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        SGStrongSelf
        if (strongSelf.playbackState == SGPlayerPlaybackStatePlaying)
        {
            CGFloat current = CMTimeGetSeconds(time);
            CGFloat duration = strongSelf.duration;
            [SGPlayerCallback callbackForPlaybackTime:strongSelf current:current duration:duration];
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
        self.playerView.playerLayer.player = nil;
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


#pragma mark - Control

- (void)play
{
    [SGPlayerActivity becomeActive:self];
    switch (self.playbackState)
    {
        case SGPlayerPlaybackStateFinished:
            [self.player seekToTime:kCMTimeZero];
            break;
        case SGPlayerPlaybackStateFailed:
            [self replaceWithContentURL:self.contentURL];
            break;
        default:
            break;
    }
    self.playbackState = SGPlayerPlaybackStatePlaying;
    [self.player play];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.playbackState == SGPlayerPlaybackStatePlaying) {
            [self.player play];
        }
    });
}

- (void)pause
{
    [SGPlayerActivity resignActive:self];
    [self.player pause];
    switch (self.playbackState) {
        case SGPlayerPlaybackStateStopped:
        case SGPlayerPlaybackStateFinished:
        case SGPlayerPlaybackStateFailed:
            return;
        default:
            break;
    }
    self.playbackState = SGPlayerPlaybackStatePaused;
}

- (void)interrupt
{
    [SGPlayerActivity resignActive:self];
    [self.player pause];
    switch (self.playbackState) {
        case SGPlayerPlaybackStateStopped:
        case SGPlayerPlaybackStateFinished:
        case SGPlayerPlaybackStateFailed:
            return;
        default:
            break;
    }
    self.playbackState = SGPlayerPlaybackStateInterrupted;
}

- (void)stop
{
    [SGPlayerActivity resignActive:self];
    [self cleanPlayer];
    [SGPlayerCallback callbackForPlaybackTime:self current:0 duration:0];
    [SGPlayerCallback callbackForLoadedTime:self current:0 duration:0];
    self.error = nil;
    self.contentURL = nil;
    self.loadedTime = 0;
    self.shouldAutoPlay = NO;
    self.playbackStateBeforSeeking = SGPlayerPlaybackStateIdle;
    self.playbackState = SGPlayerPlaybackStateStopped;
}

- (void)clear
{
    [SGPlayerActivity resignActive:self];
    [self cleanPlayer];
    [SGPlayerCallback callbackForPlaybackTime:self current:0 duration:0];
    [SGPlayerCallback callbackForLoadedTime:self current:0 duration:0];
    self.error = nil;
    self.contentURL = nil;
    self.loadedTime = 0;
    self.shouldAutoPlay = NO;
    self.playbackStateBeforSeeking = SGPlayerPlaybackStateIdle;
    self.playbackState = SGPlayerPlaybackStateIdle;
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
        if (self.playbackState == SGPlayerPlaybackStatePlaying) {
            [self.player pause];
        }
        self.playbackStateBeforSeeking = self.playbackState;
        self.playbackState = SGPlayerPlaybackStateSeeking;
        SGWeakSelf
        [self.playerItem seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                SGStrongSelf
                strongSelf.playbackState = strongSelf.playbackStateBeforSeeking;
                strongSelf.playbackStateBeforSeeking = SGPlayerPlaybackStateIdle;
                if (strongSelf.playbackState == SGPlayerPlaybackStatePlaying) {
                    [strongSelf.player play];
                }
                if (completeHandler) {
                    completeHandler(finished);
                }
                SGPlayerLog(@"SGAVPlayer seek finished");
            });
        }];
    });
}


#pragma mark - Internal Functions

- (void)setPlaybackState:(SGPlayerPlaybackState)playbackState
{
    if (_playbackState != playbackState)
    {
        SGPlayerPlaybackState previous = _playbackState;
        _playbackState = playbackState;
        [SGPlayerCallback callbackForPlaybackState:self current:_playbackState previous:previous];
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
        [SGPlayerCallback callbackForLoadedTime:self current:_loadedTime duration:duration];
    }
}

- (BOOL)seekEnable
{
    if (self.duration <= 0 || self.playerItem.status != AVPlayerItemStatusReadyToPlay) {
        return NO;
    }
    return YES;
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

- (void)playerItemDidPlayToEnd:(NSNotification *)notification
{
    self.playbackState = SGPlayerPlaybackStatePlaying;
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
                    SGPlayerLog(@"SGAVPlayer item status unknown");
//                    [self startBuffering];
                }
                    break;
                case AVPlayerItemStatusReadyToPlay:
                {
                    SGPlayerLog(@"SGAVPlayer item status ready to play");
//                    [self stopBuffering];
                }
                    break;
                case AVPlayerItemStatusFailed:
                {
                    SGPlayerLog(@"SGAVPlayer item status failed");
//                    [self stopBuffering];
                    
                    NSError * error = nil;
                    if (self.playerItem.error) {
                        error = self.playerItem.error;
                    } else if (self.player.error) {
                        error = self.player.error;
                    } else {
                        error = [NSError errorWithDomain:@"AVPlayer playback error" code:-1 userInfo:nil];
                    }
                    self.error = error;
                    self.playbackState = SGPlayerPlaybackStateFailed;
                    [SGPlayerCallback callbackForError:self error:error];
                }
                    break;
            }
        }
        else if ([keyPath isEqualToString:@"playbackBufferEmpty"])
        {
            if (self.playerItem.playbackBufferEmpty) {
//                [self startBuffering];
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
            if (interval > self.minimumPlayableDuration) {
//                [self stopBuffering];
//                [self resumeStateAfterBuffering];
            } else if (interval < 0.3 && residue > 1.5) {
//                [self startBuffering];
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
        if (type == SGAudioManagerInterruptionTypeBegin)
        {
            if (strongSelf.playbackState == SGPlayerPlaybackStatePlaying)
            {
                // fix : maybe receive interruption notification when enter foreground.
                NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
                if (timeInterval - strongSelf.lastForegroundTimeInterval > 1.5) {
                    [strongSelf interrupt];
                }
            }
        }
    } routeChange:^(id handlerTarget, SGAudioManager *audioManager, SGAudioManagerRouteChangeReason reason) {
        SGStrongSelf
        if (reason == SGAudioManagerRouteChangeReasonOldDeviceUnavailable)
        {
            if (strongSelf.playbackState == SGPlayerPlaybackStatePlaying) {
                [strongSelf interrupt];
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
            if (self.playbackState == SGPlayerPlaybackStatePlaying)
            {
                self.shouldAutoPlay = YES;
                [self interrupt];
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
            if (self.shouldAutoPlay && self.playbackState == SGPlayerPlaybackStateInterrupted) {
                self.shouldAutoPlay = NO;
                [self play];
                self.lastForegroundTimeInterval = [NSDate date].timeIntervalSince1970;
            }
        }
            break;
    }
}


@end

