//
//  SGPlayer.m
//  SGPlayer
//
//  Created by Single on 16/6/28.
//  Copyright © 2016年 single. All rights reserved.
//

#import "SGPlayer.h"
#import "SGPlayerMacro.h"
#import "SGPlayerNotification.h"
#import "SGDisplayView.h"
#import "SGAVPlayer.h"
#import "SGFFPlayer.h"

#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
#import "SGAudioManager.h"
#endif

@interface SGPlayer ()

@property (nonatomic, strong) SGDisplayView * displayView;
@property (nonatomic, assign) SGDecoderType decoderType;
@property (nonatomic, strong) SGAVPlayer * avPlayer;
@property (nonatomic, strong) SGFFPlayer * ffPlayer;

@property (nonatomic, assign) BOOL needAutoPlay;

@end

@implementation SGPlayer

+ (instancetype)player
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
        [self setupNotification];
#endif
        self.decoder = [SGPlayerDecoder defaultDecoder];
        self.contentURL = nil;
        self.videoType = SGVideoTypeNormal;
        self.backgroundMode = SGPlayerBackgroundModeAutoPlayAndPause;
        self.displayMode = SGDisplayModeNormal;
        self.viewGravityMode = SGGravityModeResizeAspect;
        self.playableBufferInterval = 2.f;
        self.viewAnimationHidden = YES;
        self.volume = 1;
    }
    return self;
}

- (void)replaceEmpty
{
    [self replaceVideoWithURL:nil];
}

- (void)replaceVideoWithURL:(nullable NSURL *)contentURL
{
    [self replaceVideoWithURL:contentURL videoType:SGVideoTypeNormal];
}

- (void)replaceVideoWithURL:(nullable NSURL *)contentURL videoType:(SGVideoType)videoType
{
    self.error = nil;
    self.contentURL = contentURL;
    self.decoderType = [self.decoder decoderTypeForContentURL:self.contentURL];
    self.videoType = videoType;
    
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            if (_ffPlayer) {
                [self.ffPlayer stop];
            }
            [self.avPlayer replaceVideo];
            break;
        case SGDecoderTypeFFmpeg:
            if (_avPlayer) {
                [self.avPlayer stop];
            }
            [self.ffPlayer replaceVideo];
            break;
        case SGDecoderTypeError:
            if (_avPlayer) {
                [self.avPlayer stop];
            }
            if (_ffPlayer) {
                [self.ffPlayer stop];
            }
            break;
    }
}

- (void)play
{
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    [UIApplication sharedApplication].idleTimerDisabled = YES;
#endif
    
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            [self.avPlayer play];
            break;
        case SGDecoderTypeFFmpeg:
            [self.ffPlayer play];
            break;
        case SGDecoderTypeError:
            break;
    }
}

- (void)pause
{
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    [UIApplication sharedApplication].idleTimerDisabled = NO;
#endif
    
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            [self.avPlayer pause];
            break;
        case SGDecoderTypeFFmpeg:
            [self.ffPlayer pause];
            break;
        case SGDecoderTypeError:
            break;
    }
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(nullable void (^)(BOOL))completeHandler
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            [self.avPlayer seekToTime:time completeHandler:completeHandler];
            break;
        case SGDecoderTypeFFmpeg:
            [self.ffPlayer seekToTime:time completeHandler:completeHandler];
            break;
        case SGDecoderTypeError:
            break;
    }
}

- (void)setContentURL:(NSURL *)contentURL
{
    _contentURL = [contentURL copy];
}

- (void)setVideoType:(SGVideoType)videoType
{
    switch (videoType) {
        case SGVideoTypeNormal:
        case SGVideoTypeVR:
            _videoType = videoType;
            break;
        default:
            _videoType = SGVideoTypeNormal;
            break;
    }
}

- (void)setVolume:(CGFloat)volume
{
    _volume = volume;
    if (_avPlayer) {
        [self.avPlayer reloadVolume];
    }
    if (_ffPlayer) {
        [self.ffPlayer reloadVolume];
    }
}

- (void)setPlayableBufferInterval:(NSTimeInterval)playableBufferInterval
{
    _playableBufferInterval = playableBufferInterval;
    if (_ffPlayer) {
        [self.ffPlayer reloadPlayableBufferInterval];
    }
}

- (void)setViewGravityMode:(SGGravityMode)viewGravityMode
{
    _viewGravityMode = viewGravityMode;
    [self.displayView reloadGravityMode];
}

- (SGPlayerState)state
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.state;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.state;
        case SGDecoderTypeError:
            return SGPlayerStateNone;
    }
}

- (CGSize)presentationSize
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.presentationSize;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.presentationSize;
        case SGDecoderTypeError:
            return CGSizeZero;
    }
}

- (NSTimeInterval)bitrate
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.bitrate;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.bitrate;
        case SGDecoderTypeError:
            return 0;
    }
}

- (NSTimeInterval)progress
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.progress;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.progress;
        case SGDecoderTypeError:
            return 0;
    }
}

- (NSTimeInterval)duration
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.duration;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.duration;
        case SGDecoderTypeError:
            return 0;
    }
}

- (NSTimeInterval)playableTime
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.playableTime;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.playableTime;
        case SGDecoderTypeError:
            return 0;
    }
}

- (SGPLFImage *)snapshot
{
    return self.displayView.snapshot;
}

- (BOOL)seeking
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.seeking;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.seeking;
        case SGDecoderTypeError:
            return NO;
    }
}

- (SGPLFView *)view
{
    return self.displayView;
}

- (SGDisplayView *)displayView
{
    if (!_displayView) {
        _displayView = [SGDisplayView displayViewWithAbstractPlayer:self];
    }
    return _displayView;
}

- (SGAVPlayer *)avPlayer
{
    if (!_avPlayer) {
        _avPlayer = [SGAVPlayer playerWithAbstractPlayer:self];
    }
    return _avPlayer;
}

- (SGFFPlayer *)ffPlayer
{
    if (!_ffPlayer) {
        _ffPlayer = [SGFFPlayer playerWithAbstractPlayer:self];
    }
    return _ffPlayer;
}

- (void)setupPlayerView:(SGPLFView *)playerView;
{
    [self cleanPlayerView];
    if (playerView) {
        [self.view addSubview:playerView];
        
        playerView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint * top = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0];
        NSLayoutConstraint * bottom = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        NSLayoutConstraint * left = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
        NSLayoutConstraint * right = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0];
        
        [self.view addConstraint:top];
        [self.view addConstraint:bottom];
        [self.view addConstraint:left];
        [self.view addConstraint:right];
    }
}

- (void)setError:(SGError * _Nullable)error
{
    if (self.error != error) {
        self->_error = error;
    }
}

- (void)cleanPlayer
{
    if (_avPlayer) {
        [self.avPlayer stop];
        self.avPlayer = nil;
    }
    if (_ffPlayer) {
        [self.ffPlayer stop];
        self.ffPlayer = nil;
    }
    [self cleanPlayerView];
    
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    [UIApplication sharedApplication].idleTimerDisabled = NO;
#endif
    
    self.needAutoPlay = NO;
    self.error = nil;
}

- (void)cleanPlayerView
{
    [self.view.subviews enumerateObjectsUsingBlock:^(__kindof SGPLFView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
}

- (void)dealloc
{
    SGPlayerLog(@"SGPlayer release");
    [self cleanPlayer];

#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[SGAudioManager manager] removeHandlerTarget:self];
#endif
}

#pragma mark - background mode

#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
- (void)setupNotification
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
                    [strongSelf pause];
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
#endif

@end


#pragma mark - Tracks Category

@implementation SGPlayer (Tracks)

- (BOOL)videoEnable
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.videoEnable;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.videoEnable;
        case SGDecoderTypeError:
            return NO;
    }
}

- (BOOL)audioEnable
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.audioEnable;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.audioEnable;
        case SGDecoderTypeError:
            return NO;
    }
}

- (SGPlayerTrack *)videoTrack
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.videoTrack;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.videoTrack;
        case SGDecoderTypeError:
            return nil;
    }
}

- (SGPlayerTrack *)audioTrack
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.audioTrack;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.audioTrack;
        case SGDecoderTypeError:
            return nil;
    }
}

- (NSArray<SGPlayerTrack *> *)videoTracks
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.videoTracks;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.videoTracks;
        case SGDecoderTypeError:
            return nil;
    }
}

- (NSArray<SGPlayerTrack *> *)audioTracks
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.audioTracks;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.audioTracks;
        case SGDecoderTypeError:
            return nil;
    }
}

- (void)selectAudioTrack:(SGPlayerTrack *)audioTrack
{
    [self selectAudioTrackIndex:audioTrack.index];
}

- (void)selectAudioTrackIndex:(int)audioTrackIndex
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            [self.avPlayer selectAudioTrackIndex:audioTrackIndex];
        case SGDecoderTypeFFmpeg:
            [self.ffPlayer selectAudioTrackIndex:audioTrackIndex];
            break;
        case SGDecoderTypeError:
            break;
    }
}

@end
