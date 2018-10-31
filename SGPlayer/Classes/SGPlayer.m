//
//  SGPlayer.m
//  SGPlayer
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGPlayer.h"
#import "SGMacro.h"
#import "SGActivity.h"
#import "SGPlayerItem+Internal.h"
#import "SGMapping.h"
#import "SGPacketOutput.h"
#import "SGConcatSource.h"
#import "SGAudioDecoder.h"
#import "SGVideoDecoder.h"
#import "SGPlaybackAudioRenderer.h"
#import "SGPlaybackVideoRenderer.h"
#import "SGAudioFrameFilter.h"

@interface SGPlayer () <NSLocking, SGRenderableDelegate>

@property (nonatomic, strong, readonly) SGPlayerItem * currentItem;
@property (nonatomic, strong, readonly) NSError * error;
@property (nonatomic, assign, readonly) CMTime duration;
@property (nonatomic, assign) CMTime actualStartTime;
@property (nonatomic, assign, readonly) SGPrepareState prepareState;
@property (nonatomic, assign, readonly) SGPlaybackState playbackState;
@property (nonatomic, assign, readonly) CMTime playbackTime;
@property (nonatomic, assign) CMTime rate;
@property (nonatomic, assign) BOOL highFrequencySeeking;
@property (nonatomic, assign, readonly) SGLoadingState loadingState;
@property (nonatomic, assign, readonly) CMTime loadedTime;
@property (nonatomic, assign) float volume;
@property (nonatomic, assign) CMTime deviceDelay;
@property (nonatomic, strong) UIView * view;
@property (nonatomic, assign) SGScalingMode scalingMode;
@property (nonatomic, assign) SGDisplayMode displayMode;
@property (nonatomic, strong) SGVRViewport * viewport;
@property (nonatomic, copy) BOOL (^displayDiscardFilter)(CMSampleTimingInfo timingInfo, NSUInteger index);
@property (nonatomic, copy) void (^displayRenderCallback)(SGVideoFrame * frame);
@property (nonatomic, weak) id <SGPlayerDelegate> delegate;
@property (nonatomic, strong) NSOperationQueue * delegateQueue;

@end

@interface SGPlayer () <SGPlayerItemDelegate, SGPlaybackClockDelegate>

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) NSCondition * prepareCondition;
@property (nonatomic, assign) NSUInteger seekingToken;
@property (nonatomic, assign) NSTimeInterval seekFinishedTimeInterval;
@property (nonatomic, assign) CMTime lastPlaybackTime;
@property (nonatomic, assign) CMTime lastLoadedTime;
@property (nonatomic, assign) CMTime lastDuration;
@property (nonatomic, assign) CMTime lastActualStartTime;

@property (nonatomic, strong) SGPlaybackAudioRenderer * audioOutput;
@property (nonatomic, strong) SGPlaybackVideoRenderer * videoOutput;

@end

@implementation SGPlayer

- (instancetype)init
{
    if (self = [super init])
    {
        self.rate = CMTimeMake(1, 1);
        self.highFrequencySeeking = NO;
        self.volume = 1.0;
        self.deviceDelay = CMTimeMake(1, 20);
        self.scalingMode = SGScalingModeResizeAspect;
        self.displayMode = SGDisplayModePlane;
        self.viewport = [[SGVRViewport alloc] init];
        self.delegateQueue = [NSOperationQueue mainQueue];
        [self destroy];
    }
    return self;
}

- (void)dealloc
{
    [self destroy];
}

#pragma mark - Asset

- (SGBasicBlock)setError:(NSError *)error
{
    if (_error != error)
    {
        _error = error;
        return ^{
            [self callback:^{
                if ([self.delegate respondsToSelector:@selector(player:didFail:)])
                {
                    [self.delegate player:self didFail:error];
                }
            }];
        };
    }
    return ^{};
}

- (CMTime)duration
{
    if (self.currentItem)
    {
        return self.currentItem.duration;
    }
    return kCMTimeZero;
}

- (NSDictionary *)metadata
{
    if (self.currentItem)
    {
        return self.currentItem.metadata;
    }
    return nil;
}

- (BOOL)replaceWithURL:(NSURL *)URL
{
    return [self replaceWithAsset:[[SGURLAsset alloc] initWithURL:URL]];
}

- (BOOL)replaceWithAsset:(SGAsset *)asset
{
    return [self replaceWithPlayerItem:[[SGPlayerItem alloc] initWithAsset:asset]];
}

- (BOOL)replaceWithPlayerItem:(SGPlayerItem *)item
{
    [self stop];
    if (!item)
    {
        return NO;
    }
    _currentItem = item;
    
    SGPlaybackClock * clock = [[SGPlaybackClock alloc] init];
    clock.delegate = self;
    
    SGPlaybackAudioRenderer * auidoRenderer = [[SGPlaybackAudioRenderer alloc] initWithClock:clock];
    auidoRenderer.delegate = self;
    auidoRenderer.key = YES;
    auidoRenderer.rate = self.rate;
    auidoRenderer.volume = self.volume;
    auidoRenderer.deviceDelay = self.deviceDelay;
    self.audioOutput = auidoRenderer;
    [self.audioOutput open];
    
    SGPlaybackVideoRenderer * videoRenderer = [[SGPlaybackVideoRenderer alloc] initWithClock:clock];
    videoRenderer.delegate = self;
    videoRenderer.key = NO;
    videoRenderer.rate = self.rate;
    videoRenderer.view = self.view;
    videoRenderer.scalingMode = self.scalingMode;
    videoRenderer.displayMode = self.displayMode;
    videoRenderer.discardFilter = self.displayDiscardFilter;
    videoRenderer.renderCallback = self.displayRenderCallback;
    videoRenderer.viewport = self.viewport;
    self.videoOutput = videoRenderer;
    [self.videoOutput open];
    
    self.currentItem.delegate = self;
    self.currentItem.audioFilter = [[SGAudioFrameFilter alloc] init];
    [self lock];
    SGBasicBlock prepareCallback = [self setPrepareState:SGPrepareStatePreparing];
    [self unlock];
    prepareCallback();
    [self.currentItem open];
    
    return YES;
}

#pragma mark - Prepare

- (SGBasicBlock)setPrepareState:(SGPrepareState)prepareState
{
    [self.prepareCondition lock];
    if (_prepareState != prepareState)
    {
        _prepareState = prepareState;
        return ^{
            [self.prepareCondition broadcast];
            [self.prepareCondition unlock];
            [self pauseOrResumeOutput];
            [self callbackForTimingIfNeeded];
            [self callback:^{
                if ([self.delegate respondsToSelector:@selector(player:didChangeState:)])
                {
                    [self.delegate player:self didChangeState:SGStateOptionPrepare];
                }
            }];
        };
    }
    return ^{
        [self.prepareCondition unlock];
    };
}

- (void)waitUntilFinishedPrepare
{
    [self.prepareCondition lock];
    while (YES)
    {
        [self lock];
        if (self.prepareState == SGPrepareStatePreparing)
        {
            [self unlock];
            [self.prepareCondition wait];
            continue;
        }
        else
        {
            [self unlock];
            break;
        }
    }
    [self.prepareCondition unlock];
}

#pragma mark - Playback

- (SGBasicBlock)setPlaybackState:(SGPlaybackState)playbackState
{
    if (_playbackState != playbackState)
    {
        _playbackState = playbackState;
        return ^{
            [self pauseOrResumeOutput];
            [self callbackForTimingIfNeeded];
            [self callback:^{
                if ([self.delegate respondsToSelector:@selector(player:didChangeState:)])
                {
                    [self.delegate player:self didChangeState:SGStateOptionPlayback];
                }
            }];
        };
    }
    return ^{};
}

- (CMTime)playbackTime
{
    if (self.currentItem.state == SGPlayerItemStateFinished)
    {
        return self.duration;
    }
    if ((self.audioOutput.state == SGRenderableStateRendering || self.audioOutput.state == SGRenderableStatePaused) && self.audioOutput.key && self.audioOutput.clock)
    {
        return self.audioOutput.clock.time;
    }
    else if ((self.videoOutput.state == SGRenderableStateRendering || self.videoOutput.state == SGRenderableStatePaused) && self.videoOutput.key && self.videoOutput.clock)
    {
        return self.videoOutput.clock.keyTime;
    }
    return kCMTimeZero;
}

- (void)setRate:(CMTime)rate
{
    if (CMTimeCompare(_rate, rate) != 0)
    {
        _rate = rate;
        self.audioOutput.rate = rate;
        self.videoOutput.rate = rate;
    }
}

- (BOOL)play
{
    [SGActivity addTarget:self];
    [self lock];
    if (self.error)
    {
        [self unlock];
        return NO;
    }
    BOOL finished = self.currentItem.state == SGPlayerItemStateFinished;
    SGBasicBlock callback = [self setPlaybackState:finished ? SGPlaybackStateFinished : SGPlaybackStatePlaying];
    [self unlock];
    callback();
    return YES;
}

- (BOOL)pause
{
    [SGActivity removeTarget:self];
    [self lock];
    if (self.error)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setPlaybackState:SGPlaybackStatePaused];
    [self unlock];
    callback();
    return YES;
}

- (BOOL)stop
{
    [self destroy];
    [self lock];
    SGBasicBlock prepareCallback = [self setPrepareState:SGPrepareStateNone];
    SGBasicBlock playbackCallback = [self setPlaybackState:SGPlaybackStateNone];
    SGBasicBlock loadingCallback = [self setLoadingState:SGLoadingStateNone];
    [self unlock];
    prepareCallback();
    playbackCallback();
    loadingCallback();
    return YES;
}

#pragma mark - Seeking

- (BOOL)seeking
{
    [self lock];
    BOOL ret = self.seekingToken != 0;
    [self unlock];
    return ret;
}

- (BOOL)seekable
{
    return self.currentItem.seekable;
}

- (BOOL)seekToTime:(CMTime)time completionHandler:(void (^)(CMTime, NSError *))completionHandler
{
    if (![self seekable])
    {
        return NO;
    }
    [self lock];
    if (self.error)
    {
        [self unlock];
        return NO;
    }
    if (self.seekingToken == 0)
    {
        self.seekFinishedTimeInterval = 0;
    }
    self.seekingToken++;
    NSInteger seekingToken = self.seekingToken;
    [self unlock];
    [self pauseOrResumeOutput];
    SGWeakSelf
    [self.currentItem seekToTime:time completionHandler:^(CMTime time, NSError * error) {
        SGStrongSelf
        [self lock];
        if (seekingToken == self.seekingToken)
        {
            self.seekingToken = 0;
            self.seekFinishedTimeInterval = [NSDate date].timeIntervalSince1970;
        }
        [self unlock];
        [self pauseOrResumeOutput];
        if (completionHandler)
        {
            [self callback:^{
                completionHandler(time, error);
            }];
        }
    }];
    return YES;
}

#pragma mark - Loading

- (SGBasicBlock)setLoadingState:(SGLoadingState)loadingState
{
    if (_loadingState != loadingState)
    {
        _loadingState = loadingState;
        return ^{
            [self pauseOrResumeOutput];
            [self callbackForTimingIfNeeded];
            [self callback:^{
                if ([self.delegate respondsToSelector:@selector(player:didChangeState:)])
                {
                    [self.delegate player:self didChangeState:SGStateOptionLoading];
                }
            }];
        };
    }
    return ^{};
}

- (CMTime)loadedTime
{
    if (self.currentItem.state == SGPlayerItemStateFinished)
    {
        return self.duration;
    }
    CMTime time = self.playbackTime;
    CMTime loadedDuration = self.loadedDuration;
    CMTime duration = self.duration;
    CMTime loadedTime = CMTimeAdd(time, loadedDuration);
    return CMTimeMinimum(loadedTime, duration);
}

- (CMTime)loadedDuration
{
    if (self.currentItem)
    {
        return self.currentItem.capacity.duration;
    }
    return kCMTimeZero;
}

#pragma mark - Audio

- (void)setVolume:(float)volume
{
    if (_volume != volume)
    {
        _volume = volume;
        self.audioOutput.volume = _volume;
    }
}

- (void)setDeviceDelay:(CMTime)deviceDelay
{
    if (CMTimeCompare(_deviceDelay, deviceDelay) != 0)
    {
        _deviceDelay = deviceDelay;
        self.audioOutput.deviceDelay = deviceDelay;
    }
}

#pragma mark - Video

- (void)setView:(UIView *)view
{
    if (_view != view)
    {
        _view = view;
        self.videoOutput.view = _view;
    }
}

- (void)setScalingMode:(SGScalingMode)scalingMode
{
    if (_scalingMode != scalingMode)
    {
        _scalingMode = scalingMode;
        self.videoOutput.scalingMode = scalingMode;
    }
}

- (void)setDisplayMode:(SGDisplayMode)displayMode
{
    if (_displayMode != displayMode)
    {
        _displayMode = displayMode;
        self.videoOutput.displayMode = displayMode;
    }
}

- (void)setViewport:(SGVRViewport *)viewport
{
    if (_viewport != viewport)
    {
        _viewport = viewport;
        self.videoOutput.viewport = viewport;
    }
}

- (void)setDisplayDiscardFilter:(BOOL (^)(CMSampleTimingInfo, NSUInteger))displayDiscardFilter
{
    if (_displayDiscardFilter != displayDiscardFilter)
    {
        _displayDiscardFilter = displayDiscardFilter;
        self.videoOutput.discardFilter = displayDiscardFilter;
    }
}

- (void)setDisplayRenderCallback:(void (^)(SGVideoFrame *))displayRenderCallback
{
    if (_displayRenderCallback != displayRenderCallback)
    {
        _displayRenderCallback = displayRenderCallback;
        self.videoOutput.renderCallback = displayRenderCallback;
    }
}

- (UIImage *)originalImage
{
    return self.videoOutput.originalImage;
}

- (UIImage *)snapshot
{
    return self.videoOutput.snapshot;
}

#pragma mark - Delegate

- (void)callback:(void (^)(void))block
{
    if (!block)
    {
        return;
    }
    if (self.delegateQueue)
    {
        NSOperation * operation = [NSBlockOperation blockOperationWithBlock:^{
            block();
        }];
        [self.delegateQueue addOperation:operation];
    }
    else
    {
        block();
    }
}

- (void)callbackForTimingIfNeeded
{
    [self lock];
    if (self.error)
    {
        [self unlock];
        return;
    }
    [self unlock];
    SGTimeOption option = 0;
    CMTime playbackTime = self.playbackTime;
    CMTime loadedTime = self.loadedTime;
    CMTime duration = self.duration;
    CMTime actualStartTime = self.actualStartTime;
    if (CMTIME_IS_VALID(playbackTime) &&
        CMTimeCompare(playbackTime, self.lastPlaybackTime) != 0)
    {
        option |= SGTimeOptionPlayback;
    }
    if (CMTIME_IS_VALID(loadedTime) &&
        CMTimeCompare(loadedTime, self.lastLoadedTime) != 0)
    {
        option |= SGTimeOptionLoaded;
    }
    if (CMTIME_IS_VALID(duration) &&
        CMTimeCompare(duration, self.lastDuration) != 0)
    {
        option |= SGTimeOptionDuration;
    }
    if (CMTIME_IS_VALID(actualStartTime) &&
        CMTimeCompare(actualStartTime, self.lastActualStartTime))
    {
        option |= SGTimeOptionActualStartTime;
    }
    if (option != 0)
    {
        self.lastPlaybackTime = playbackTime;
        self.lastLoadedTime = loadedTime;
        self.lastDuration = duration;
        self.lastActualStartTime = actualStartTime;
        [self callback:^{
            if ([self.delegate respondsToSelector:@selector(player:didChangeTime:)])
            {
                [self.delegate player:self didChangeTime:option];
            }
        }];
    }
}

#pragma mark - Internal

- (void)pauseOrResumeOutput
{
    [self lock];
    BOOL seeking = self.seekingToken != 0;
    BOOL playback = self.playbackState == SGPlaybackStatePlaying;
    BOOL loading = self.loadingState == SGLoadingStateLoading || self.loadingState == SGLoadingStateFinished;
    [self unlock];
    if (self.highFrequencySeeking)
    {
        BOOL seekDelay = ([NSDate date].timeIntervalSince1970 - self.seekFinishedTimeInterval) < 0.30;
        if (seekDelay)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((0.31) * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
                [self pauseOrResumeOutput];
            });
            return;
        }
    }
    if (!seeking && playback && loading && self.currentItem.capacity.count > 0)
    {
        [self.audioOutput resume];
        [self.videoOutput resume];
    }
    else
    {
        [self.audioOutput pause];
        [self.videoOutput pause];
    }
}

- (void)destroy
{
    [SGActivity removeTarget:self];
    [self.currentItem close];
    _currentItem = nil;
    self.audioOutput.clock.delegate = nil;
    self.audioOutput = nil;
    self.videoOutput = nil;
    self.lastPlaybackTime = CMTimeMake(-1900, 1);
    self.lastLoadedTime = CMTimeMake(-1900, 1);
    self.lastDuration = CMTimeMake(-1900, 1);
    self.lastActualStartTime = CMTimeMake(-1900, 1);
    _error = nil;
    _actualStartTime = kCMTimeInvalid;
}

#pragma mark - SGPlayerItemDelegate

- (void)playerItem:(SGPlayerItem *)playerItem didChangeState:(SGPlayerItemState)state
{
    if (playerItem.state == SGPlayerItemStateOpened)
    {
        [playerItem start];
        [self lock];
        SGBasicBlock prepareCallback = [self setPrepareState:SGPrepareStateFinished];
        SGBasicBlock loadingCallback = [self setLoadingState:SGLoadingStateLoading];
        [self unlock];
        prepareCallback();
        loadingCallback();
    }
    else if (playerItem.state == SGPlayerItemStateReading)
    {
        SGBasicBlock playbackCallback = ^{};
        [self lock];
        if (self.playbackState == SGPlaybackStateFinished)
        {
            playbackCallback =  [self setPlaybackState:SGPlaybackStatePlaying];
        }
        [self unlock];
        playbackCallback();
    }
    if (self.currentItem.state == SGPlayerItemStateFinished)
    {
        [self lock];
        SGBasicBlock loadingCallback = [self setLoadingState:SGLoadingStateFinished];
        SGBasicBlock playbackCallback = [self setPlaybackState:SGPlaybackStateFinished];
        [self unlock];
        loadingCallback();
        playbackCallback();
    }
    else if (playerItem.state == SGPlayerItemStateFailed)
    {
        [self lock];
        SGBasicBlock failedCallback =  [self setError:playerItem.error];
        [self unlock];
        failedCallback();
    }
}

- (void)playerItem:(SGPlayerItem *)playerItem didChangeCapacity:(SGCapacity *)capacity track:(SGTrack *)track
{
    if (track.type == SGMediaTypeAudio) {
        NSLog(@"audio duration : %f, %lld, %lld", CMTimeGetSeconds(capacity.duration), capacity.size, capacity.count);
    }
//    if (track.type == SGMediaTypeVideo) {
//        NSLog(@"video duration : %f, %lld, %lld", CMTimeGetSeconds(capacity.duration), capacity.size, capacity.count);
//    }
    [self pauseOrResumeOutput];
    [self callbackForTimingIfNeeded];
}

#pragma mark - SGPlaybackClockDelegate

- (void)playbackClockDidChangeStartTime:(SGPlaybackClock *)playbackClock
{
    self.actualStartTime = playbackClock.startTime;
    [self callbackForTimingIfNeeded];
}

#pragma mark - SGRenderableDelegate

- (void)renderable:(id <SGRenderable>)renderable didChangeState:(SGRenderableState)state {}
- (void)renderable:(id <SGRenderable>)renderable didChangeCapacity:(SGCapacity *)capacity {}
- (void)renderable:(id <SGRenderable>)renderable didRenderFrame:(__kindof SGFrame *)frame {}

- (__kindof SGFrame *)renderableNeedMoreFrame:(id <SGRenderable>)renderable
{
    if (renderable == self.audioOutput) {
        return [self.currentItem nextAudioFrame];
    }
    return nil;
}

- (__kindof SGFrame *)renderableNeedMoreFrame:(id <SGRenderable>)renderable ptsHandler:(BOOL (^)(CMTime *, CMTime *))ptsHandler drop:(BOOL)drop
{
    if (renderable == self.videoOutput) {
        return [self.currentItem nextVideoFrameWithPTSHandler:ptsHandler drop:drop];
    }
    return nil;
}

#pragma mark - NSLocking

- (void)lock
{
    if (!self.coreLock)
    {
        self.coreLock = [[NSLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
