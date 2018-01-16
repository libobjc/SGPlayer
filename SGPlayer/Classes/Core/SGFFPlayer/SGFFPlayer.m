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
    [self clean];
    [self.audioManager unregisterAudioSession];
}


- (void)replaceWithContentURL:(NSURL *)contentURL
{
    [self clean];
    //    if (!self.contentURL) return;
    
    //    [self.abstractPlayer.displayView playerOutputTypeFF];
    self.decoder = [SGFFDecoder decoderWithContentURL:contentURL
                                             delegate:self
                                    videoOutputConfig:nil
                                    audioOutputConfig:self];
    //    self.decoder.formatContextOptions = [self.abstractPlayer.decoder FFmpegFormatContextOptions];
    //    self.decoder.codecContextOptions = [self.abstractPlayer.decoder FFmpegCodecContextOptions];
    //    self.decoder.hardwareAccelerateEnable = self.abstractPlayer.decoder.hardwareAccelerateEnableForFFmpeg;
    [self.decoder open];
}


#pragma mark - Control

- (void)play
{
    [SGPlayerActivity becomeActive:self];
    self.playing = YES;
    [self.decoder resume];
    
//    switch (self.state) {
//        case SGPlayerStateFinished:
//            [self seekToTime:0];
//            break;
//        case SGPlayerStateNone:
//        case SGPlayerStateFailed:
//        case SGPlayerStateBuffering:
//            self.state = SGPlayerStateBuffering;
//            break;
//        case SGPlayerStateSuspend:
//            if (self.decoder.buffering) {
//                self.state = SGPlayerStateBuffering;
//            } else {
//                self.state = SGPlayerStatePlaying;
//            }
//            break;
//        case SGPlayerStateReadyToPlay:
//        case SGPlayerStatePlaying:
//            self.state = SGPlayerStatePlaying;
//            break;
//    }
}

- (void)pause
{
    [SGPlayerActivity resignActive:self];
    self.playing = NO;
    [self.decoder pause];
    
//    switch (self.state) {
//        case SGPlayerStateNone:
//        case SGPlayerStateSuspend:
//            break;
//        case SGPlayerStateFailed:
//        case SGPlayerStateReadyToPlay:
//        case SGPlayerStateFinished:
//        case SGPlayerStatePlaying:
//        case SGPlayerStateBuffering:
//        {
//            self.state = SGPlayerStateSuspend;
//        }
//            break;
//    }
}

- (void)interrupt
{
    [SGPlayerActivity resignActive:self];
}

- (void)stop
{
    [SGPlayerActivity resignActive:self];
    [self clean];
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completionHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^)(BOOL))completionHandler
{
    if (!self.decoder.prepareToDecode) {
        if (completionHandler) {
            completionHandler(NO);
        }
        return;
    }
    [self.decoder seekToTime:time completeHandler:completionHandler];
}


#pragma mark - Setter & Getter

- (void)setPlaybackState:(SGPlayerPlaybackState)playbackState
{
    
}

- (void)setLoadState:(SGPlayerLoadState)loadState
{
    
}

- (NSTimeInterval)duration
{
    return 0;
}

- (NSTimeInterval)currentTime
{
    return 0;
}

- (NSTimeInterval)loadedTime
{
    return 0;
}

- (BOOL)seekEnable
{
    return self.decoder.seekEnable;
}

//- (void)setState:(SGPlayerState)state
//{
//    if (_state != state) {
////        SGPlayerState temp = _state;
//        _state = state;
//        if (_state != SGPlayerStateFailed) {
////            self.abstractPlayer.error = nil;
//        }
//        if (_state == SGPlayerStatePlaying) {
//            [self.audioManager playWithDelegate:self];
//        } else {
//            [self.audioManager pause];
//        }
////        [SGPlayerNotification postPlayer:self.abstractPlayer statePrevious:temp current:_state];
//    }
//}

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
    [self cleanDecoder];
    [self cleanFrame];
    [self cleanPlayer];
}

- (void)cleanPlayer
{
    self.playing = NO;
    //    self.state = SGPlayerStateNone;
    self.progress = 0;
    self.playableTime = 0;
    self.prepareToken = NO;
    self.lastPostProgressTime = 0;
    self.lastPostPlayableTime = 0;
    //    [self.abstractPlayer.displayView playerOutputTypeEmpty];
    //    [self.abstractPlayer.displayView rendererTypeEmpty];
}

- (void)cleanFrame
{
    [self.currentAudioFrame stopPlaying];
    self.currentAudioFrame = nil;
}

- (void)cleanDecoder
{
    if (self.decoder) {
        [self.decoder closeFile];
        self.decoder = nil;
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
