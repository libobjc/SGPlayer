//
//  SGFFPlayer.m
//  SGPlayer
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFPlayer.h"
#import "SGFFPlayerView.h"
#import "SGFFDecoder.h"
#import "SGAudioManager.h"

#import "SGPlayerMacro.h"
#import "SGPlayerUtil.h"
#import "SGPlayerCallback.h"
#import "SGPlayerActivity.h"
#import "SGPlayerDefinesPrivate.h"
#import "SGPlayerBackgroundHandler.h"
#import "SGPlayerAudioInterruptHandler.h"


@interface SGFFPlayer () <SGPlayerPrivate, SGFFDecoderDelegate, SGFFDecoderAudioOutputConfig, SGAudioManagerDelegate>

@property (nonatomic, assign) NSInteger tagInternal;
@property (nonatomic, strong) SGPlayerBackgroundHandler * backgroundHandler;
@property (nonatomic, strong) SGPlayerAudioInterruptHandler * audioInterruptHandler;
@property (nonatomic, strong) SGFFPlayerView * playerView;

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, assign) SGPlayerPlaybackState playbackState;
@property (nonatomic, assign) SGPlayerPlaybackState playbackStateBeforSeeking;
@property (nonatomic, assign) SGPlayerLoadState loadState;
@property (nonatomic, assign) NSTimeInterval loadedTime;
@property (nonatomic, copy) NSError * error;

@property (nonatomic, strong) SGFFDecoder * decoder;
@property (nonatomic, strong) SGAudioManager * audioManager;

@property (nonatomic, assign) BOOL prepareToken;
@property (nonatomic, assign) NSTimeInterval progress;

@property (nonatomic, assign) NSTimeInterval lastPostProgressTime;
@property (nonatomic, assign) NSTimeInterval lastPostPlayableTime;

@property (nonatomic, assign) BOOL playing;

@property (nonatomic, strong) SGFFAudioFrame * currentAudioFrame;

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
        self.audioManager = [SGAudioManager manager];
        [self.audioManager registerAudioSession];
    }
    return self;
}

- (void)dealloc
{
    [SGPlayerActivity resignActive:self];
    [self cleanDecoder];
    [self cleanFrame];
    [self.audioManager unregisterAudioSession];
}


- (void)replaceWithContentURL:(NSURL *)contentURL
{
    [self clean];
    if (contentURL == nil) {
        return;
    }
    self.contentURL = contentURL;
    self.decoder = [SGFFDecoder decoderWithContentURL:contentURL
                                             delegate:self
                                    videoOutputConfig:nil
                                    audioOutputConfig:self];
    [self.decoder open];
}


#pragma mark - Control

- (void)play
{
    [SGPlayerActivity becomeActive:self];
    switch (self.playbackState)
    {
        case SGPlayerPlaybackStateFinished:
            if (ABS(self.currentTime - self.duration) < 0.1) {
                [self.decoder seekToTime:0];
            }
            break;
        case SGPlayerPlaybackStateFailed:
            [self replaceWithContentURL:self.contentURL];
            break;
        default:
            break;
    }
    self.playbackState = SGPlayerPlaybackStatePlaying;
    [self.decoder resume];
}

- (void)pause
{
    [SGPlayerActivity resignActive:self];
    [self.decoder pause];
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
    [self.decoder pause];
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
    [self cleanFrame];
    self.playbackState = SGPlayerPlaybackStateStopped;
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completionHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^)(BOOL))completionHandler
{
    if (!self.seekEnable || !self.decoder.prepareToDecode) {
        if (completionHandler) {
            completionHandler(NO);
        }
        return;
    }
    if (self.playbackState == SGPlayerPlaybackStatePlaying) {
        [self.decoder pause];
    }
    self.playbackStateBeforSeeking = self.playbackState;
    self.playbackState = SGPlayerPlaybackStateSeeking;
    SGWeakSelf
    [self.decoder seekToTime:time completeHandler:^(BOOL finished) {
        SGStrongSelf
        strongSelf.playbackState = strongSelf.playbackStateBeforSeeking;
        strongSelf.playbackStateBeforSeeking = SGPlayerPlaybackStateIdle;
        if (strongSelf.playbackState == SGPlayerPlaybackStatePlaying) {
            [strongSelf.decoder resume];
        }
        if (completionHandler) {
            completionHandler(finished);
        }
        SGPlayerLog(@"SGPlayer seek finished");
    }];
}


#pragma mark - Setter & Getter

- (void)setPlaybackState:(SGPlayerPlaybackState)playbackState
{
    if (_playbackState != playbackState)
    {
        SGPlayerPlaybackState previous = _playbackState;
        _playbackState = playbackState;
        if (_playbackState == SGPlayerPlaybackStatePlaying) {
            [self.audioManager playWithDelegate:self];
        } else {
            [self.audioManager pause];
        }
        [SGPlayerCallback callbackForPlaybackState:self current:_playbackState previous:previous];
    }
}

- (void)setLoadState:(SGPlayerLoadState)loadState
{
    if (_loadState != loadState)
    {
        SGPlayerLoadState previous = _loadState;
        _loadState = loadState;
        [SGPlayerCallback callbackForLoadState:self current:_loadState previous:previous];
    }
}

- (NSTimeInterval)duration
{
    return self.decoder.duration;
}

- (NSTimeInterval)currentTime
{
    return self.decoder.progress;
}

- (NSTimeInterval)loadedTime
{
    return self.decoder.bufferedDuration;
}

- (BOOL)seekEnable
{
    return self.decoder.seekEnable;
}

- (void)setProgress:(NSTimeInterval)progress
{
    if (_progress != progress) {
        _progress = progress;
        NSTimeInterval duration = self.duration;
//        double percent = [self percentForTime:_progress duration:duration];
        if (_progress <= 0.000001 || _progress == duration) {
//            [SGPlayerNotification postPlayer:self.abstractPlayer progressPercent:@(percent) current:@(_progress) total:@(duration)];
        } else {
            NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
            if (currentTime - self.lastPostProgressTime >= 1) {
                self.lastPostProgressTime = currentTime;
                /*
                if (!self.decoder.seekEnable && duration <= 0) {
                    duration = _progress;
                }
                 */
//                [SGPlayerNotification postPlayer:self.abstractPlayer progressPercent:@(percent) current:@(_progress) total:@(duration)];
            }
        }
    }
}

- (void)setPlayableTime:(NSTimeInterval)playableTime
{
    NSTimeInterval duration = self.duration;
    if (playableTime > duration) {
        playableTime = duration;
    } else if (playableTime < 0) {
        playableTime = 0;
    }
    
//    if (_playableTime != playableTime) {
//        _playableTime = playableTime;
//        double percent = [self percentForTime:_playableTime duration:duration];
//        if (_playableTime == 0 || _playableTime == duration) {
////            [SGPlayerNotification postPlayer:self.abstractPlayer playablePercent:@(percent) current:@(_playableTime) total:@(duration)];
//        } else if (!self.decoder.endOfFile && self.decoder.seekEnable) {
//            NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
//            if (currentTime - self.lastPostPlayableTime >= 1) {
//                self.lastPostPlayableTime = currentTime;
////                [SGPlayerNotification postPlayer:self.abstractPlayer playablePercent:@(percent) current:@(_playableTime) total:@(duration)];
//            }
//        }
//    }
}

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
    [self cleanFrame];
    self.playbackState = SGPlayerPlaybackStateIdle;
}

- (void)cleanDecoder
{
    if (self.decoder) {
        [self.decoder closeFile];
        self.decoder = nil;
    }
}

- (void)cleanProperty
{
    self.playing = NO;
    self.progress = 0;
    self.playableTime = 0;
    self.prepareToken = NO;
    self.lastPostProgressTime = 0;
    self.lastPostPlayableTime = 0;
}

- (void)cleanFrame
{
    if (self.currentAudioFrame)
    {
        [self.currentAudioFrame stopPlaying];
        self.currentAudioFrame = nil;
    }
}

#pragma mark - Callback

- (void)callbackForTimes
{
    
}


#pragma mark - SGFFDecoderDelegate

- (void)decoderWillOpenInputStream:(SGFFDecoder *)decoder
{
//    self.state = SGPlayerStateBuffering;
}

- (void)decoderDidPrepareToDecodeFrames:(SGFFDecoder *)decoder
{
    if (self.decoder.videoEnable) {
//        [self.abstractPlayer.displayView rendererTypeOpenGL];
    }
}

- (void)decoderDidEndOfFile:(SGFFDecoder *)decoder
{
    self.playableTime = self.duration;
}

- (void)decoderDidPlaybackFinished:(SGFFDecoder *)decoder
{
//    self.state = SGPlayerStateFinished;
}

- (void)decoder:(SGFFDecoder *)decoder didChangeValueOfBuffering:(BOOL)buffering
{
//    if (buffering) {
//        self.state = SGPlayerStateBuffering;
//    } else {
//        if (self.playing) {
//            self.state = SGPlayerStatePlaying;
//        } else if (!self.prepareToken) {
//            self.state = SGPlayerStateReadyToPlay;
//            self.prepareToken = YES;
//        } else {
//            self.state = SGPlayerStateSuspend;
//        }
//    }
}

- (void)decoder:(SGFFDecoder *)decoder didChangeValueOfBufferedDuration:(NSTimeInterval)bufferedDuration
{
    self.playableTime = self.progress + bufferedDuration;
}

- (void)decoder:(SGFFDecoder *)decoder didChangeValueOfProgress:(NSTimeInterval)progress
{
    self.progress = progress;
}

- (void)decoder:(SGFFDecoder *)decoder didError:(NSError *)error
{
    [self errorHandler:error];
}

- (void)errorHandler:(NSError *)error
{
//    SGError * obj = [[SGError alloc] init];
//    obj.error = error;
//    self.abstractPlayer.error = obj;
//    self.state = SGPlayerStateFailed;
//    [SGPlayerNotification postPlayer:self.abstractPlayer error:obj];
}


#pragma mark - SGFFPlayerOutput

- (SGFFVideoFrame *)playerOutputGetVideoFrameWithCurrentPostion:(NSTimeInterval)currentPostion
                                                currentDuration:(NSTimeInterval)currentDuration
{
    if (self.decoder) {
        return [self.decoder decoderVideoOutputGetVideoFrameWithCurrentPostion:currentPostion
                                                               currentDuration:currentDuration];
    }
    return nil;
}


#pragma mark - Audio Config

- (Float64)decoderAudioOutputConfigGetSamplingRate
{
    return self.audioManager.samplingRate;
}

- (UInt32)decoderAudioOutputConfigGetNumberOfChannels
{
    return self.audioManager.numberOfChannels;
}

- (void)audioManager:(SGAudioManager *)audioManager outputData:(float *)outputData numberOfFrames:(UInt32)numberOfFrames numberOfChannels:(UInt32)numberOfChannels
{
    if (!self.playing) {
        memset(outputData, 0, numberOfFrames * numberOfChannels * sizeof(float));
        return;
    }
    @autoreleasepool
    {
        while (numberOfFrames > 0)
        {
            if (!self.currentAudioFrame) {
                self.currentAudioFrame = [self.decoder decoderAudioOutputGetAudioFrame];
                [self.currentAudioFrame startPlaying];
            }
            if (!self.currentAudioFrame) {
                memset(outputData, 0, numberOfFrames * numberOfChannels * sizeof(float));
                return;
            }
            
            const Byte * bytes = (Byte *)self.currentAudioFrame->samples + self.currentAudioFrame->output_offset;
            const NSUInteger bytesLeft = self.currentAudioFrame->length - self.currentAudioFrame->output_offset;
            const NSUInteger frameSizeOf = numberOfChannels * sizeof(float);
            const NSUInteger bytesToCopy = MIN(numberOfFrames * frameSizeOf, bytesLeft);
            const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
            
            memcpy(outputData, bytes, bytesToCopy);
            numberOfFrames -= framesToCopy;
            outputData += framesToCopy * numberOfChannels;
            
            if (bytesToCopy < bytesLeft) {
                self.currentAudioFrame->output_offset += bytesToCopy;
            } else {
                [self.currentAudioFrame stopPlaying];
                self.currentAudioFrame = nil;
            }
        }
    }
}


@end
