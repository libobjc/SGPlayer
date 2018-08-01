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
#import "SGFFSession.h"
#import "SGFFAudioPlaybackOutput.h"
#import "SGFFVideoPlaybackOutput.h"

@interface SGPlayer () <NSLocking, SGFFSessionDelegate>

@property (nonatomic, strong) NSRecursiveLock * coreLock;

@property (nonatomic, assign) SGPlaybackState playbackStateBeforSeeking;
@property (nonatomic, copy) NSError * error;

@property (nonatomic, strong) SGFFSession * session;
@property (nonatomic, strong) SGFFAudioPlaybackOutput * audioOutput;
@property (nonatomic, strong) SGFFVideoPlaybackOutput * videoOutput;

@end

@implementation SGPlayer

@synthesize playbackState = _playbackState;
@synthesize loadingState = _loadingState;

- (instancetype)init
{
    if (self = [super init])
    {
        
    }
    return self;
}

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
    SGFFSessionConfiguration * configuration = [[SGFFSessionConfiguration alloc] init];
    self.audioOutput = [[SGFFAudioPlaybackOutput alloc] init];
    self.videoOutput = [[SGFFVideoPlaybackOutput alloc] init];
    configuration.audioOutput = self.audioOutput;
    configuration.videoOutput = self.videoOutput;
    [self updateView];
    self.session = [[SGFFSession alloc] init];
    self.session.URL = self.URL;
    self.session.delegate = self;
    self.session.configuration = configuration;
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
            if (self.session.state == SGFFSessionStateFinished &&
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

- (BOOL)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler
{
    [self lock];
    if (![self.session seekableToTime:time])
    {
        [self unlock];
        return NO;
    }
    [self startSeeking];
    SGWeakSelf
    [self.session seekToTime:time completionHandler:^(BOOL success) {
        SGStrongSelf
        [strongSelf lock];
        [strongSelf finishSeeking];
        if (completionHandler)
        {
            completionHandler(success);
        }
        [strongSelf unlock];
        SGPlayerLog(@"SGPlayer seek finished, %d", success);
    }];
    [self unlock];
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
        switch (previousState)
        {
            case SGPlaybackStateSeeking:
                self.playbackStateBeforSeeking = SGPlaybackStateNone;
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

#pragma mark - SGFFSessionDelegate

- (void)sessionDidChangeState:(SGFFSession *)session
{
    [self lock];
    if (session.state == SGFFSourceStateOpened)
    {
        [self.session read];
        self.loadingState = SGLoadingStateLoading;
    }
    [self unlock];
}

- (void)sessionDidChangeCapacity:(SGFFSession *)session
{
    [self lock];
    if (self.session.state == SGFFSessionStateFinished)
    {
        self.loadingState = SGLoadingStateFinished;
    }
    [self playOrPause];
    if (self.session.state == SGFFSessionStateFinished &&
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
