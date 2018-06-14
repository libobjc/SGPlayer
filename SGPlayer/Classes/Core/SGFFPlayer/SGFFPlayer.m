//
//  SGFFPlayer.m
//  SGPlayer
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFPlayer.h"
#import "SGFFSession.h"
#import "SGFFPlayerView.h"
#import "SGFFAudioOutput.h"
#import "SGFFVideoOutput.h"

#import "SGPlayerMacro.h"
#import "SGPlayerUtil.h"
#import "SGPlayerCallback.h"
#import "SGPlayerActivity.h"
#import "SGPlayerDefinesPrivate.h"
#import "SGPlayerBackgroundHandler.h"
#import "SGPlayerAudioInterruptHandler.h"


@interface SGFFPlayer () <SGPlayerPrivate, SGFFSessionDelegate, SGFFVideoOutputDelegate>

@property (nonatomic, assign) NSInteger tagInternal;
@property (nonatomic, strong) SGPlayerBackgroundHandler * backgroundHandler;
@property (nonatomic, strong) SGPlayerAudioInterruptHandler * audioInterruptHandler;

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, assign) SGPlayerPlaybackState playbackState;
@property (nonatomic, assign) SGPlayerPlaybackState playbackStateBeforSeeking;
@property (nonatomic, assign) SGPlayerLoadState loadState;
@property (nonatomic, assign) NSTimeInterval loadedTime;
@property (nonatomic, copy) NSError * error;

@property (nonatomic, strong) SGFFSession * session;
@property (nonatomic, strong) SGFFAudioOutput * audioOutput;
@property (nonatomic, strong) SGFFVideoOutput * videoOutput;
@property (nonatomic, strong) SGFFPlayerView * playerView;

@end

@implementation SGFFPlayer

- (instancetype)init
{
    if (self = [super init])
    {
        self.tagInternal = [SGPlayerUtil globalPlayerTag];
        self.backgroundHandler = [SGPlayerBackgroundHandler backgroundHandlerWithPlayer:self];
        self.audioInterruptHandler = [SGPlayerAudioInterruptHandler audioInterruptHandlerWithPlayer:self];
        self.backgroundMode = SGPlayerBackgroundModeAutoPlayAndPause;
        self.minimumPlayableDuration = 2.f;
        
        self.playerView = [[SGFFPlayerView alloc] initWithFrame:CGRectZero];
    }
    return self;
}

- (void)dealloc
{
    [SGPlayerActivity resignActive:self];
    [self cleanDecoder];
}


- (void)replaceWithContentURL:(NSURL *)contentURL
{
    [self clean];
    if (contentURL == nil)
    {
        return;
    }
    self.contentURL = contentURL;
    
    SGFFSessionConfiguration * configuration = [[SGFFSessionConfiguration alloc] init];
    self.audioOutput = [[SGFFAudioOutput alloc] init];
    self.videoOutput = [[SGFFVideoOutput alloc] init];
    self.videoOutput.delegate = self;
    configuration.audioOutput = self.audioOutput;
    configuration.videoOutput = self.videoOutput;
    
    self.session = [SGFFSession sessionWithContentURL:self.contentURL
                                             delegate:self
                                        configuration:configuration];
    [self.session open];
}


#pragma mark - Control

- (void)play
{
    [SGPlayerActivity becomeActive:self];
    switch (self.playbackState)
    {
        case SGPlayerPlaybackStateFinished:
            if (ABS(self.currentTime - self.duration) < 0.1)
            {
                [self.session seekToTime:kCMTimeZero completionHandler:nil];
            }
            break;
        case SGPlayerPlaybackStateFailed:
            [self replaceWithContentURL:self.contentURL];
            break;
        default:
            break;
    }
    self.playbackState = SGPlayerPlaybackStatePlaying;
}

- (void)playOrPause
{
    if (_playbackState == SGPlayerPlaybackStatePlaying && _loadState == SGPlayerLoadStatePlayable) {
        [self.audioOutput play];
    } else {
        [self.audioOutput pause];
    }
}

- (void)pause
{
    [SGPlayerActivity resignActive:self];
//    [self.decoder pause];
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
//    [self.decoder pause];
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
    [self cleanDecoder];
    [self cleanProperty];
    [self cleanTimes];
    self.playbackState = SGPlayerPlaybackStateStopped;
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completionHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^)(BOOL))completionHandler
{
    [self.session seekToTime:CMTimeMakeWithSeconds(time, 10000) completionHandler:completionHandler];
    
//    if (!self.seekEnable || !self.decoder.prepareToDecode) {
//        if (completionHandler) {
//            completionHandler(NO);
//        }
//        return;
//    }
//    if (self.playbackState == SGPlayerPlaybackStatePlaying) {
//        [self.decoder pause];
//    }
//    self.playbackStateBeforSeeking = self.playbackState;
//    self.playbackState = SGPlayerPlaybackStateSeeking;
//    SGWeakSelf
//    [self.decoder seekToTime:time completeHandler:^(BOOL finished) {
//        SGStrongSelf
//        strongSelf.playbackState = strongSelf.playbackStateBeforSeeking;
//        strongSelf.playbackStateBeforSeeking = SGPlayerPlaybackStateIdle;
//        if (strongSelf.playbackState == SGPlayerPlaybackStatePlaying) {
//            [strongSelf.decoder resume];
//        }
//        if (completionHandler) {
//            completionHandler(finished);
//        }
//        SGPlayerLog(@"SGPlayer seek finished");
//    }];
}


#pragma mark - Setter & Getter

- (void)setPlaybackState:(SGPlayerPlaybackState)playbackState
{
    if (_playbackState != playbackState)
    {
        SGPlayerPlaybackState previous = _playbackState;
        _playbackState = playbackState;
        [self playOrPause];
        [SGPlayerCallback callbackForPlaybackState:self current:_playbackState previous:previous];
    }
}

- (void)setLoadState:(SGPlayerLoadState)loadState
{
    if (_loadState != loadState)
    {
        SGPlayerLoadState previous = _loadState;
        _loadState = loadState;
        [self playOrPause];
        [SGPlayerCallback callbackForLoadState:self current:_loadState previous:previous];
    }
}

//- (NSTimeInterval)duration
//{
//    return self.decoder.duration;
//}
//
//- (NSTimeInterval)currentTime
//{
//    return self.decoder.progress;
//}
//
//- (NSTimeInterval)loadedTime
//{
//    return self.decoder.bufferedDuration;
//}
//
//- (BOOL)seekEnable
//{
//    return self.decoder.seekEnable;
//}

- (NSInteger)tag
{
    return self.tagInternal;
}

- (SGPLFView *)view
{
    return self.playerView;
}


#pragma mark - clean

- (void)clean
{
    [SGPlayerActivity resignActive:self];
    [self cleanDecoder];
    [self cleanProperty];
    [self cleanTimes];
    self.playbackState = SGPlayerPlaybackStateIdle;
}

- (void)cleanDecoder
{
    if (self.session)
    {
        [self.session close];
        self.session = nil;
    }
}

- (void)cleanProperty
{
    
}

- (void)cleanTimes
{
    [self callbackForTimes];
}


#pragma mark - Callback

- (void)callbackForTimes
{
    
}


#pragma mark - SGFFSessionDelegate

- (void)sessionDidOpened:(SGFFSession *)session
{
    [self.session read];
}

- (void)sessionDidFailed:(SGFFSession *)session
{
    
}

- (void)sessionDidFinished:(SGFFSession *)session
{
    
}

- (void)sessionDidChangeCapacity:(SGFFSession *)session
{
    Float64 duration = CMTimeGetSeconds(session.loadedDuration);
    if (duration >= self.minimumPlayableDuration) {
        self.loadState = SGPlayerLoadStatePlayable;
    } else {
        self.loadState = SGPlayerLoadStateLoading;
    }
}


#pragma mark - SGFFVideoOutputDelegate

- (void)videoOutputDidChangeDisplayView:(SGFFVideoOutput *)output
{
    self.videoOutput.displayView.frame = self.playerView.bounds;
    [self.playerView addSubview:self.videoOutput.displayView];
}

@end
