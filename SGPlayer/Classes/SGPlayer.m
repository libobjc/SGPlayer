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

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, assign) SGPlaybackState playbackStateBeforSeeking;
@property (nonatomic, strong) SGSession * session;
@property (nonatomic, strong) SGAudioPlaybackOutput * audioOutput;
@property (nonatomic, strong) SGVideoPlaybackOutput * videoOutput;
@property (nonatomic, strong) SGPlaybackTimeSync * timeSync;

@end

@implementation SGPlayer

@synthesize playbackState = _playbackState;
@synthesize loadingState = _loadingState;

- (void)dealloc
{
    [SGActivity resignActive:self];
    [self closeSession];
}

- (void)replaceWithURL:(NSURL *)URL
{
    [self destory];
    _URL = URL;
    if (self.URL == nil)
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

#pragma mark - Control

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
        case SGPlaybackStateStopped:
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
    [SGActivity resignActive:self];
    [self closeSession];
    self.playbackState = SGPlaybackStateStopped;
}

- (BOOL)seekable
{
    return self.session.seekable;
}

- (BOOL)seekToTime:(CMTime)time
{
    return [self seekToTime:time completionHandler:nil];
}

- (BOOL)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL, CMTime))completionHandler
{
    if (![self.session seekableToTime:time])
    {
        return NO;
    }
    [self startSeeking];
    SGWeakSelf
    [self.session seekToTime:time completionHandler:^(BOOL success, CMTime time) {
        SGStrongSelf
        [self finishSeeking];
        if (completionHandler)
        {
            completionHandler(success, time);
        }
        SGPlayerLog(@"SGPlayer seek finished, %d", success);
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

- (void)startSeeking
{
    self.playbackState = SGPlaybackStateSeeking;
}

- (void)finishSeeking
{
    self.playbackState = self.playbackStateBeforSeeking;
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
    [SGActivity resignActive:self];
    [self closeSession];
    self.playbackState = SGPlaybackStateNone;
}

- (void)closeSession
{
    if (self.session)
    {
        [self.session close];
        self.session = nil;
    }
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

#pragma mark - NSLocking

//- (void)lock
//{
//    if (!self.coreLock)
//    {
//        self.coreLock = [[NSLock alloc] init];
//    }
//    [self.coreLock lock];
//}
//
//- (void)unlock
//{
//    [self.coreLock unlock];
//}

@end
