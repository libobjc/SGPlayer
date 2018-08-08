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

@interface SGPlayer () <NSLocking, SGSessionDelegate>

@property (nonatomic, strong) NSRecursiveLock * coreLock;

@property (nonatomic, assign) SGPlaybackState playbackStateBeforSeeking;
@property (nonatomic, copy) NSError * error;

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
    [self lock];
    [self destory];
    _URL = URL;
    if (self.URL == nil)
    {
        [self unlock];
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
    [self unlock];
}

#pragma mark - Control

- (void)play
{
    [self lock];
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
    [self unlock];
}

- (void)pause
{
    [self lock];
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
    [self unlock];
}

- (void)stop
{
    [self lock];
    [SGActivity resignActive:self];
    [self closeSession];
    self.playbackState = SGPlaybackStateStopped;
    [self unlock];
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
    [self lock];
    if (![self.session seekableToTime:time])
    {
        [self unlock];
        return NO;
    }
    [self startSeeking];
    [self unlock];
    SGWeakSelf
    [self.session seekToTime:time completionHandler:^(BOOL success, CMTime time) {
        SGStrongSelf
        [self lock];
        [self finishSeeking];
        if (completionHandler)
        {
            completionHandler(success, time);
        }
        [self unlock];
        SGPlayerLog(@"SGPlayer seek finished, %d", success);
    }];
    return YES;
}

#pragma mark - Internal

- (void)playOrPause
{
    [self lock];
    if (self.playbackState != SGPlaybackStatePlaying)
    {
        [self.audioOutput pause];
        [self unlock];
        return;
    }
    if (self.loadingState != SGLoadingStateLoading &&
        self.loadingState != SGLoadingStateFinished)
    {
        [self.audioOutput pause];
        [self unlock];
        return;
    }
    if (CMTimeCompare(self.session.loadedDuration, kCMTimeZero) <= 0)
    {
        [self.audioOutput pause];
        [self unlock];
        return;
    }
    [self.audioOutput play];
    [self unlock];
}

- (void)startSeeking
{
    [self lock];
    self.playbackState = SGPlaybackStateSeeking;
    [self unlock];
}

- (void)finishSeeking
{
    [self lock];
    self.playbackState = self.playbackStateBeforSeeking;
    [self unlock];
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
    [self lock];
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
        if ([self.delegate respondsToSelector:@selector(player:didChangePlaybackState:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate player:self didChangePlaybackState:playbackState];
            });
        }
    }
    [self unlock];
}

- (void)setLoadingState:(SGLoadingState)loadingState
{
    [self lock];
    if (_loadingState != loadingState)
    {
        _loadingState = loadingState;
        if ([self.delegate respondsToSelector:@selector(player:didChangeLoadingState:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate player:self didChangeLoadingState:loadingState];
            });
        }
    }
    [self unlock];
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
    [self lock];
    [SGActivity resignActive:self];
    [self closeSession];
    self.playbackState = SGPlaybackStateNone;
    [self unlock];
}

- (void)closeSession
{
    [self lock];
    if (self.session)
    {
        [self.session close];
        self.session = nil;
    }
    [self unlock];
}

#pragma mark - SGSessionDelegate

- (void)sessionDidChangeState:(SGSession *)session
{
    [self lock];
    if (session.state == SGSessionStateOpened)
    {
        [self.session read];
        self.loadingState = SGLoadingStateLoading;
    }
    [self unlock];
}

- (void)sessionDidChangeCapacity:(SGSession *)session
{
    [self lock];
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
    [self unlock];
}

#pragma mark - NSLocking

- (void)lock
{
    if (!self.coreLock)
    {
        self.coreLock = [[NSRecursiveLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
