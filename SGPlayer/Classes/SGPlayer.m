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
#import "SGPeriodTimer.h"
#import "SGSession.h"
#import "SGAudioPlaybackOutput.h"
#import "SGVideoPlaybackOutput.h"

@interface SGPlayer () <SGSessionDelegate>

@property (nonatomic, strong) SGSession * session;
@property (nonatomic, strong) SGAudioPlaybackOutput * audioOutput;
@property (nonatomic, strong) SGVideoPlaybackOutput * videoOutput;
@property (nonatomic, strong) SGPlaybackTimeSync * timeSync;
@property (nonatomic, assign) SGPlaybackState stateBeforSeeking;
@property (nonatomic, strong) NSLock * stateLock;
@property (nonatomic, strong) NSLock * loadingStateLock;

@end

@implementation SGPlayer

@synthesize state = _state;
@synthesize loadingState = _loadingState;

- (instancetype)init
{
    if (self = [super init])
    {
        self.stateLock = [[NSLock alloc] init];
        self.loadingStateLock = [[NSLock alloc] init];
        self.delegateQueue = dispatch_get_main_queue();
        [SGPeriodTimer addTarget:self selector:@selector(periodTimerHandler)];
    }
    return self;
}

- (void)dealloc
{
    [SGPeriodTimer removeTarget:self];
    [self destoryInternal];
}

#pragma mark - Interface

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
    [self.stateLock lock];
    switch (self.state)
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
    SGBasicBlock callback = [self setState:SGPlaybackStatePlaying];
    [self.stateLock unlock];
    callback();
}

- (void)pause
{
    [SGActivity resignActive:self];
    [self.stateLock lock];
    switch (self.state)
    {
        case SGPlaybackStateNone:
        case SGPlaybackStateFinished:
        case SGPlaybackStateFailed:
            [self.stateLock unlock];
            return;
        default:
            break;
    }
    SGBasicBlock callback = [self setState:SGPlaybackStatePaused];
    [self.stateLock unlock];
    callback();
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
    [self.stateLock lock];
    if (self.state == SGPlaybackStateNone ||
        self.state == SGPlaybackStateFailed)
    {
        [self.stateLock unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGPlaybackStateSeeking];
    [self.stateLock unlock];
    callback();
    SGWeakSelf
    [self.session seekToTime:time completionHandler:^(BOOL success, CMTime time) {
        SGStrongSelf
        [self.stateLock lock];
        SGBasicBlock callback = [self setState:self.stateBeforSeeking];
        [self.stateLock unlock];
        callback();
        if (completionHandler)
        {
            [self callback:^{
                completionHandler(success, time);
            }];
        }
    }];
    return YES;
}

#pragma mark - Internal

- (void)playAndPause
{
    [self.stateLock lock];
    if (self.state != SGPlaybackStatePlaying)
    {
        [self.stateLock unlock];
        [self.audioOutput pause];
        return;
    }
    [self.stateLock unlock];
    [self.loadingStateLock lock];
    if (self.loadingState != SGLoadingStateLoading &&
        self.loadingState != SGLoadingStateFinished)
    {
        [self.loadingStateLock unlock];
        [self.audioOutput pause];
        return;
    }
    [self.loadingStateLock unlock];
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

- (SGBasicBlock)setState:(SGPlaybackState)state
{
    if (_state != state)
    {
        SGPlaybackState previousState = _state;
        _state = state;
        switch (_state)
        {
            case SGPlaybackStateSeeking:
                self.stateBeforSeeking = previousState;
                break;
            default:
                break;
        }
        return ^{
            [self playAndPause];
            [self callback:^{
                [self.delegate playerDidChangeState:self];
            }];
        };
    }
    return ^{};
}

- (SGBasicBlock)setLoadingState:(SGLoadingState)loadingState
{
    if (_loadingState != loadingState)
    {
        _loadingState = loadingState;
        return ^{
            [self callback:^{
                [self.delegate playerDidChangeLoadingState:self];
            }];
        };
    }
    return ^{};
}

- (CMTime)time
{
    if (self.timeSync)
    {
        return self.timeSync.time;
    }
    return kCMTimeZero;
}

- (CMTime)loadedTime
{
    CMTime time = self.time;
    CMTime loadedDuration = self.loadedDuration;
    CMTime duration = self.duration;
    return CMTimeMinimum(CMTimeAdd(time, loadedDuration), duration);
}

- (CMTime)duration
{
    if (self.session)
    {
        return self.session.duration;
    }
    return kCMTimeZero;
}

- (CMTime)loadedDuration
{
    if (self.session)
    {
        return self.session.loadedDuration;
    }
    return kCMTimeZero;
}

#pragma mark - Destory

- (void)destory
{
    [self destoryInternal];
    [self.stateLock lock];
    SGBasicBlock callback = [self setState:SGPlaybackStateNone];
    [self.stateLock unlock];
    [self.loadingStateLock lock];
    SGBasicBlock loadingStateCallback = [self setLoadingState:SGLoadingStateNone];
    [self.loadingStateLock unlock];
    callback();
    loadingStateCallback();
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
        [self.loadingStateLock lock];
        SGBasicBlock loadingStateCallback = [self setLoadingState:SGLoadingStateLoading];
        [self.loadingStateLock unlock];
        loadingStateCallback();
    }
}

- (void)sessionDidChangeCapacity:(SGSession *)session
{
    if (self.session.state == SGSessionStateFinished)
    {
        [self.loadingStateLock lock];
        SGBasicBlock loadingStateCallback = [self setLoadingState:SGLoadingStateFinished];
        [self.loadingStateLock unlock];
        loadingStateCallback();
    }
    if (self.session.state == SGSessionStateFinished &&
        CMTimeCompare(self.session.loadedDuration, kCMTimeZero) <= 0)
    {
        [self.stateLock lock];
        SGBasicBlock callback = [self setState:SGPlaybackStateFinished];
        [self.stateLock unlock];
        callback();
    }
    [self playAndPause];
}

#pragma mark - SGPeriodTimer

- (void)periodTimerHandler
{
    NSLog(@"time : %f", CMTimeGetSeconds(self.time));
}

#pragma mark - Callback

- (void)callback:(void (^)(void))block
{
    if (!block)
    {
        return;
    }
    if (self.delegateQueue)
    {
        dispatch_async(self.delegateQueue, ^{
            block();
        });
    }
    else
    {
        block();
    }
}

@end
