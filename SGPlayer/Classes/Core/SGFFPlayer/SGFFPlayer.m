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
#import "SGFFAudioPlaybackOutput.h"
#import "SGFFVideoPlaybackOutput.h"
#import "SGFFPlayerView.h"

#import "SGPlayerMacro.h"
#import "SGPlayerUtil.h"
#import "SGPlayerActivity.h"


@interface SGFFPlayer () <NSLocking, SGFFSessionDelegate>

@property (nonatomic, assign) SGPlayerPlaybackState playbackStateBeforSeeking;
@property (nonatomic, copy) NSError * error;

@property (nonatomic, strong) SGFFSession * session;
@property (nonatomic, strong) SGFFAudioPlaybackOutput * audioOutput;
@property (nonatomic, strong) SGFFVideoPlaybackOutput * videoOutput;
@property (nonatomic, strong) SGFFPlayerView * displayView;
@property (nonatomic, strong) NSRecursiveLock * coreLock;

@end

@implementation SGFFPlayer

@synthesize playbackState = _playbackState;
@synthesize loadingState = _loadingState;

- (instancetype)init
{
    if (self = [super init])
    {
        self.displayView = [[SGFFPlayerView alloc] initWithFrame:CGRectZero];
    }
    return self;
}

- (void)dealloc
{
    [SGPlayerActivity resignActive:self];
    [self closeSession];
}

- (void)replaceWithURL:(NSURL *)URL
{
    [self destory];
    if (URL == nil)
    {
        return;
    }
    _URL = URL;
    
    SGFFSessionConfiguration * configuration = [[SGFFSessionConfiguration alloc] init];
    self.audioOutput = [[SGFFAudioPlaybackOutput alloc] init];
    self.videoOutput = [[SGFFVideoPlaybackOutput alloc] init];
    configuration.audioOutput = self.audioOutput;
    configuration.videoOutput = self.videoOutput;
    self.displayView.view = self.videoOutput.view;
    
    self.session = [[SGFFSession alloc] init];
    self.session.URL = self.URL;
    self.session.delegate = self;
    self.session.configuration = configuration;
    [self.session open];
}

#pragma mark - Control

- (void)play
{
    [SGPlayerActivity becomeActive:self];
    switch (self.playbackState)
    {
        case SGPlayerPlaybackStateFinished:
            [self.session seekToTime:kCMTimeZero completionHandler:nil];
            break;
        case SGPlayerPlaybackStateFailed:
            [self replaceWithURL:self.URL];
            break;
        default:
            break;
    }
    self.playbackState = SGPlayerPlaybackStatePlaying;
}

- (void)pause
{
    [SGPlayerActivity resignActive:self];
    switch (self.playbackState)
    {
        case SGPlayerPlaybackStateStopped:
        case SGPlayerPlaybackStateFinished:
        case SGPlayerPlaybackStateFailed:
            return;
        default:
            break;
    }
    self.playbackState = SGPlayerPlaybackStatePaused;
}

- (void)stop
{
    [SGPlayerActivity resignActive:self];
    [self closeSession];
    self.playbackState = SGPlayerPlaybackStateStopped;
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
    if (!self.seekable)
    {
        return NO;
    }
    SGWeakSelf
    BOOL ret = [self.session seekToTime:time completionHandler:^(BOOL success) {
        SGStrongSelf
        strongSelf.playbackState = strongSelf.playbackStateBeforSeeking;
        strongSelf.playbackStateBeforSeeking = SGPlayerPlaybackStateNone;
        if (completionHandler)
        {
            completionHandler(success);
        }
        SGPlayerLog(@"SGPlayer seek finished, %d", success);
    }];
    if (ret)
    {
        self.playbackState = SGPlayerPlaybackStateSeeking;
    }
    return ret;
}

#pragma mark - Internal

- (void)playOrPause
{
    if (self.playbackState != SGPlayerPlaybackStatePlaying)
    {
        [self.audioOutput pause];
        return;
    }
    if (self.loadingState != SGPlayerLoadingStateLoading &&
        self.loadingState != SGPlayerLoadingStateFinished)
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

#pragma mark - Setter & Getter

- (void)setPlaybackState:(SGPlayerPlaybackState)playbackState
{
    [self lock];
    if (_playbackState != playbackState)
    {
        SGPlayerPlaybackState previousState = _playbackState;
        _playbackState = playbackState;
        switch (_playbackState)
        {
            case SGPlayerPlaybackStateSeeking:
                self.playbackStateBeforSeeking = previousState;
                break;
            default:
                break;
        }
        [self playOrPause];
        if ([self.delegate respondsToSelector:@selector(playerDidChangePlaybackState:)])
        {
            [self.delegate playerDidChangePlaybackState:self];
        }
    }
    [self unlock];
}

- (void)setLoadingState:(SGPlayerLoadingState)loadingState
{
    [self lock];
    if (_loadingState != loadingState)
    {
        _loadingState = loadingState;
        if ([self.delegate respondsToSelector:@selector(playerDidChangeLoadingState:)])
        {
            [self.delegate playerDidChangeLoadingState:self];
        }
    }
    [self unlock];
}

- (SGPLFView *)view
{
    return self.displayView;
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
    [SGPlayerActivity resignActive:self];
    [self closeSession];
    self.playbackState = SGPlayerPlaybackStateNone;
}

- (void)closeSession
{
    if (self.session)
    {
        [self.session close];
        self.session = nil;
    }
}

#pragma mark - SGFFSessionDelegate

- (void)sessionDidChangeState:(SGFFSession *)session
{
    if (session.state == SGFFSourceStateOpened)
    {
        [self.session read];
        self.loadingState = SGPlayerLoadingStateLoading;
    }
}

- (void)sessionDidChangeCapacity:(SGFFSession *)session
{
    if (self.session.state == SGFFSessionStateFinished)
    {
        self.loadingState = SGPlayerLoadingStateFinished;
    }
    [self playOrPause];
    if (self.session.state == SGFFSessionStateFinished &&
        CMTimeCompare(self.session.loadedDuration, kCMTimeZero) <= 0)
    {
        self.playbackState = SGPlayerPlaybackStateFinished;
    }
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
