//
//  SGFFPlayer.m
//  SGPlayer
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGPlayer.h"
#import "SGMacro.h"
#import "SGActivity.h"
#import "SGSession.h"
#import "SGAudioPlaybackOutput.h"
#import "SGVideoPlaybackOutput.h"

@interface SGPlayer () <SGSessionDelegate>

@property (nonatomic, strong) SGSession * session;
@property (nonatomic, strong) SGAudioPlaybackOutput * audioOutput;
@property (nonatomic, strong) SGVideoPlaybackOutput * videoOutput;
@property (nonatomic, strong) SGPlaybackTimeSync * timeSync;
@property (nonatomic, assign) SGPlaybackState playbackStateBeforSeeking;

@end

@implementation SGPlayer

@synthesize playbackState = _playbackState;
@synthesize loadingState = _loadingState;

- (void)dealloc
{
    [self destoryInternal];
}

- (void)replaceWithURL:(NSURL *)URL
{
    [self destory];
    _URL = URL;
    if (!self.URL)
    {
        return;
    }
    self.audioOutput = [[SGAudioPlaybackOutput alloc] init];
    self.videoOutput = [[SGVideoPlaybackOutput alloc] init];
    self.timeSync = [[SGPlaybackTimeSync alloc] init];
    self.audioOutput.timeSync = self.timeSync;
    self.videoOutput.timeSync = self.timeSync;
    SGSessionConfiguration * configuration = [[SGSessionConfiguration alloc] init];
    configuration.audioOutput = self.audioOutput;
    configuration.videoOutput = self.videoOutput;
    [self updateView];
    self.session = [[SGSession alloc] initWithURL:self.URL configuration:configuration];
    self.session.delegate = self;
    [self.session open];
}

- (void)play
{
    [SGActivity becomeActive:self];
    switch (self.playbackState)
    {
        case SGPlaybackStateFinished:
            if (self.session.state == SGSessionStateFinished &&
                CMTimeCompare(self.session.loadedDuration, kCMTimeZero) <= 0)
            {
                [self.session seekToTime:kCMTimeZero completionHandler:nil];
            }
            break;
        case SGPlaybackStateFailed:
            [self replaceWithURL:self.URL];
            break;
        default:
            break;
    }
    self.playbackState = SGPlaybackStatePlaying;
}

- (void)pause
{
    [SGActivity resignActive:self];
    switch (self.playbackState)
    {
        case SGPlaybackStateNone:
        case SGPlaybackStateFinished:
        case SGPlaybackStateFailed:
            return;
        default:
            break;
    }
    self.playbackState = SGPlaybackStatePaused;
}

- (void)stop
{
    [self destory];
}

- (BOOL)seekable
{
    return self.session.seekable;
}

- (BOOL)seekableToTime:(CMTime)time
{
    return [self.session seekableToTime:time];
}

- (BOOL)seekToTime:(CMTime)time
{
    return [self seekToTime:time completionHandler:nil];
}

- (BOOL)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL, CMTime))completionHandler
{
    if (![self seekableToTime:time])
    {
        return NO;
    }
    if (self.playbackState == SGPlaybackStateNone ||
        self.playbackState == SGPlaybackStateFailed)
    {
        return NO;
    }
    self.playbackState = SGPlaybackStateSeeking;
    SGWeakSelf
    [self.session seekToTime:time completionHandler:^(BOOL success, CMTime time) {
        SGStrongSelf
        self.playbackState = self.playbackStateBeforSeeking;
        if (completionHandler)
        {
            completionHandler(success, time);
        }
    }];
    return YES;
}

#pragma mark - Internal

- (void)playOrPause
{
    if (self.playbackState != SGPlaybackStatePlaying)
    {
        [self.audioOutput pause];
        return;
    }
    if (self.loadingState != SGLoadingStateLoading &&
        self.loadingState != SGLoadingStateFinished)
    {
        [self.audioOutput pause];
        return;
    }
    if (CMTimeCompare(self.session.loadedDuration, kCMTimeZero) <= 0)
    {
        [self.audioOutput pause];
        return;
    }
    [self.audioOutput play];
}

- (void)updateView
{
    [self.videoOutput.view removeFromSuperview];
    self.videoOutput.view.frame = _view.bounds;
    [_view addSubview:self.videoOutput.view];
}

#pragma mark - Setter & Getter

- (void)setView:(UIView *)view
{
    if (_view != view)
    {
        _view = view;
        [self updateView];
    }
}

- (void)setPlaybackState:(SGPlaybackState)playbackState
{
    if (_playbackState != playbackState)
    {
        SGPlaybackState previousState = _playbackState;
        _playbackState = playbackState;
        switch (_playbackState)
        {
            case SGPlaybackStateSeeking:
                self.playbackStateBeforSeeking = previousState;
                break;
            default:
                break;
        }
        [self playOrPause];
        [self.delegate playerDidChangePlaybackState:self];
    }
}

- (void)setLoadingState:(SGLoadingState)loadingState
{
    if (_loadingState != loadingState)
    {
        _loadingState = loadingState;
        [self.delegate playerDidChangeLoadingState:self];
    }
}

- (CMTime)duration
{
    if (self.session)
    {
        return self.session.duration;
    }
    return kCMTimeZero;
}

#pragma mark - Clean

- (void)destory
{
    [self destoryInternal];
    self.playbackState = SGPlaybackStateNone;
    self.loadingState = SGLoadingStateNone;
    _URL = nil;
    _error = nil;
}

- (void)destoryInternal
{
    [SGActivity resignActive:self];
    [self.session close];
    self.session = nil;
}

#pragma mark - SGSessionDelegate

- (void)sessionDidChangeState:(SGSession *)session
{
    if (session.state == SGSessionStateOpened)
    {
        [self.session read];
        self.loadingState = SGLoadingStateLoading;
    }
}

- (void)sessionDidChangeCapacity:(SGSession *)session
{
    if (self.session.state == SGSessionStateFinished)
    {
        self.loadingState = SGLoadingStateFinished;
    }
    [self playOrPause];
    if (self.session.state == SGSessionStateFinished &&
        CMTimeCompare(self.session.loadedDuration, kCMTimeZero) <= 0)
    {
        self.playbackState = SGPlaybackStateFinished;
    }
}

@end
