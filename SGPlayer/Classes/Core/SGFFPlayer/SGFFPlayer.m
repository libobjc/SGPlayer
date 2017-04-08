//
//  SGFFPlayer.m
//  SGPlayer
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFPlayer.h"
#import "SGFFDecoder.h"
#import "SGAudioManager.h"
#import "SGPlayerNotification.h"
#import "SGPlayerMacro.h"
#import "SGPlayer+DisplayView.h"

@interface SGFFPlayer () <SGFFDecoderDelegate, SGFFDecoderVideoOutputConfig, SGFFDecoderAudioOutputConfig, SGAudioManagerDelegate>

@property (nonatomic, strong) NSLock * stateLock;

@property (nonatomic, weak) SGPlayer * abstractPlayer;

@property (nonatomic, strong) SGFFDecoder * decoder;
@property (nonatomic, strong) SGAudioManager * audioManager;

@property (nonatomic, assign) BOOL prepareToken;
@property (nonatomic, assign) SGPlayerState state;
@property (nonatomic, assign) NSTimeInterval progress;

@property (nonatomic, assign) NSTimeInterval lastPostProgressTime;
@property (nonatomic, assign) NSTimeInterval lastPostPlayableTime;

@property (nonatomic, assign) BOOL playing;

@property (nonatomic, strong) SGFFAudioFrame * currentAudioFrame;

@end

@implementation SGFFPlayer

+ (instancetype)playerWithAbstractPlayer:(SGPlayer *)abstractPlayer
{
    return [[self alloc] initWithAbstractPlayer:abstractPlayer];
}

- (instancetype)initWithAbstractPlayer:(SGPlayer *)abstractPlayer
{
    if (self = [super init]) {
        self.abstractPlayer = abstractPlayer;
        self.abstractPlayer.displayView.playerOutputFF = self;
        self.stateLock = [[NSLock alloc] init];
        self.audioManager = [SGAudioManager manager];
        [self.audioManager registerAudioSession];
    }
    return self;
}

- (void)play
{
    self.playing = YES;
    [self.decoder resume];
    
    switch (self.state) {
        case SGPlayerStateFinished:
            [self seekToTime:0];
            break;
        case SGPlayerStateNone:
        case SGPlayerStateFailed:
        case SGPlayerStateBuffering:
            self.state = SGPlayerStateBuffering;
            break;
        case SGPlayerStateSuspend:
            if (self.decoder.buffering) {
                self.state = SGPlayerStateBuffering;
            } else {
                self.state = SGPlayerStatePlaying;
            }
            break;
        case SGPlayerStateReadyToPlay:
        case SGPlayerStatePlaying:
            self.state = SGPlayerStatePlaying;
            break;
    }
}

- (void)pause
{
    self.playing = NO;
    [self.decoder pause];
    
    switch (self.state) {
        case SGPlayerStateNone:
        case SGPlayerStateSuspend:
            break;
        case SGPlayerStateFailed:
        case SGPlayerStateReadyToPlay:
        case SGPlayerStateFinished:
        case SGPlayerStatePlaying:
        case SGPlayerStateBuffering:
        {
            self.state = SGPlayerStateSuspend;
        }
            break;
    }
}

- (void)stop
{
    [self clean];
}

- (BOOL)seekEnable
{
    return self.decoder.seekEnable;
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL finished))completeHandler
{
    if (!self.decoder.prepareToDecode) {
        if (completeHandler) {
            completeHandler(NO);
        }
        return;
    }
    [self.decoder seekToTime:time completeHandler:completeHandler];
}

- (void)setState:(SGPlayerState)state
{
    [self.stateLock lock];
    if (_state != state) {
        SGPlayerState temp = _state;
        _state = state;
        if (_state != SGPlayerStateFailed) {
            self.abstractPlayer.error = nil;
        }
        if (_state == SGPlayerStatePlaying) {
            [self.audioManager playWithDelegate:self];
        } else {
            [self.audioManager pause];
        }
        [SGPlayerNotification postPlayer:self.abstractPlayer statePrevious:temp current:_state];
    }
    [self.stateLock unlock];
}

- (double)percentForTime:(NSTimeInterval)time duration:(NSTimeInterval)duration
{
    double percent = 0;
    if (time > 0) {
        if (duration <= 0) {
            percent = 1;
        } else {
            percent = time / duration;
        }
    }
    return percent;
}

- (void)setProgress:(NSTimeInterval)progress
{
    if (_progress != progress) {
        _progress = progress;
        NSTimeInterval duration = self.duration;
        double percent = [self percentForTime:_progress duration:duration];
        if (_progress <= 0.000001 || _progress == duration) {
            [SGPlayerNotification postPlayer:self.abstractPlayer progressPercent:@(percent) current:@(_progress) total:@(duration)];
        } else {
            NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
            if (currentTime - self.lastPostProgressTime >= 1) {
                self.lastPostProgressTime = currentTime;
                /*
                if (!self.decoder.seekEnable && duration <= 0) {
                    duration = _progress;
                }
                 */
                [SGPlayerNotification postPlayer:self.abstractPlayer progressPercent:@(percent) current:@(_progress) total:@(duration)];
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
    
    if (_playableTime != playableTime) {
        _playableTime = playableTime;
        double percent = [self percentForTime:_playableTime duration:duration];
        if (_playableTime == 0 || _playableTime == duration) {
            [SGPlayerNotification postPlayer:self.abstractPlayer playablePercent:@(percent) current:@(_playableTime) total:@(duration)];
        } else if (!self.decoder.endOfFile && self.decoder.seekEnable) {
            NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
            if (currentTime - self.lastPostPlayableTime >= 1) {
                self.lastPostPlayableTime = currentTime;
                [SGPlayerNotification postPlayer:self.abstractPlayer playablePercent:@(percent) current:@(_playableTime) total:@(duration)];
            }
        }
    }
}

- (NSTimeInterval)duration
{
    return self.decoder.duration;
}

- (CGSize)presentationSize
{
    if (self.decoder.prepareToDecode) {
        return self.decoder.presentationSize;
    }
    return CGSizeZero;
}

- (NSTimeInterval)bitrate
{
    if (self.decoder.prepareToDecode) {
        return self.decoder.bitrate;
    }
    return 0;
}

- (BOOL)videoDecodeOnMainThread
{
    return self.decoder.videoDecodeOnMainThread;
}

- (void)reloadVolume
{
    self.audioManager.volume = self.abstractPlayer.volume;
}

- (void)reloadPlayableBufferInterval
{
    self.decoder.minBufferedDruation = self.abstractPlayer.playableBufferInterval;
}

#pragma mark - replace video

- (void)replaceVideo
{
    [self clean];
    if (!self.abstractPlayer.contentURL) return;
    
    [self.abstractPlayer.displayView playerOutputTypeFF];
    self.decoder = [SGFFDecoder decoderWithContentURL:self.abstractPlayer.contentURL
                                             delegate:self
                                    videoOutputConfig:self
                                    audioOutputConfig:self];
    self.decoder.formatContextOptions = [self.abstractPlayer.decoder FFmpegFormatContextOptions];
    self.decoder.codecContextOptions = [self.abstractPlayer.decoder FFmpegCodecContextOptions];
    self.decoder.hardwareAccelerateEnable = self.abstractPlayer.decoder.hardwareAccelerateEnableForFFmpeg;
    [self.decoder open];
    [self reloadVolume];
    [self reloadPlayableBufferInterval];
}

#pragma mark - SGFFDecoderDelegate

- (void)decoderWillOpenInputStream:(SGFFDecoder *)decoder
{
    self.state = SGPlayerStateBuffering;
}

- (void)decoderDidPrepareToDecodeFrames:(SGFFDecoder *)decoder
{
    if (self.decoder.videoEnable) {
        [self.abstractPlayer.displayView rendererTypeOpenGL];
    }
}

- (void)decoderDidEndOfFile:(SGFFDecoder *)decoder
{
    self.playableTime = self.duration;
}

- (void)decoderDidPlaybackFinished:(SGFFDecoder *)decoder
{
    self.state = SGPlayerStateFinished;
}

- (void)decoder:(SGFFDecoder *)decoder didChangeValueOfBuffering:(BOOL)buffering
{
    if (buffering) {
        self.state = SGPlayerStateBuffering;
    } else {
        if (self.playing) {
            self.state = SGPlayerStatePlaying;
        } else if (!self.prepareToken) {
            self.state = SGPlayerStateReadyToPlay;
            self.prepareToken = YES;
        } else {
            self.state = SGPlayerStateSuspend;
        }
    }
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
    SGError * obj = [[SGError alloc] init];
    obj.error = error;
    self.abstractPlayer.error = obj;
    self.state = SGPlayerStateFailed;
    [SGPlayerNotification postPlayer:self.abstractPlayer error:obj];
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
    self.state = SGPlayerStateNone;
    self.progress = 0;
    self.playableTime = 0;
    self.prepareToken = NO;
    self.lastPostProgressTime = 0;
    self.lastPostPlayableTime = 0;
    [self.abstractPlayer.displayView playerOutputTypeEmpty];
    [self.abstractPlayer.displayView rendererTypeEmpty];
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

- (void)dealloc
{
    [self clean];
    [self.audioManager unregisterAudioSession];
    SGPlayerLog(@"SGFFPlayer release");
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


#pragma mark - Video Config

- (void)decoderVideoOutputConfigDidUpdateMaxPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond
{
    
}

- (BOOL)decoderVideoOutputConfigAVCodecContextDecodeAsync
{
    if (self.abstractPlayer.videoType == SGVideoTypeVR) {
        return NO;
    }
    return YES;
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


#pragma mark - Track Info

- (BOOL)videoEnable
{
    return self.decoder.videoEnable;
}

- (BOOL)audioEnable
{
    return self.decoder.audioEnable;
}

- (SGPlayerTrack *)videoTrack
{
    return [self playerTrackFromFFTrack:self.decoder.videoTrack];
}

- (SGPlayerTrack *)audioTrack
{
    return [self playerTrackFromFFTrack:self.decoder.audioTrack];
}

- (NSArray <SGPlayerTrack *> *)videoTracks
{
    return [self playerTracksFromFFTracks:self.decoder.videoTracks];
}

- (NSArray <SGPlayerTrack *> *)audioTracks
{
    return [self playerTracksFromFFTracks:self.decoder.audioTracks];;
}

- (void)selectAudioTrackIndex:(int)audioTrackIndex
{
    [self.decoder selectAudioTrackIndex:audioTrackIndex];
}

- (SGPlayerTrack *)playerTrackFromFFTrack:(SGFFTrack *)track
{
    if (track) {
        SGPlayerTrack * obj = [[SGPlayerTrack alloc] init];
        obj.index = track.index;
        obj.name = track.metadata.language;
        return obj;
    }
    return nil;
}

- (NSArray <SGPlayerTrack *> *)playerTracksFromFFTracks:(NSArray <SGFFTrack *> *)tracks
{
    NSMutableArray <SGPlayerTrack *> * array = [NSMutableArray array];
    for (SGFFTrack * obj in tracks) {
        SGPlayerTrack * track = [self playerTrackFromFFTrack:obj];
        [array addObject:track];
    }
    if (array.count > 0) {
        return array;
    }
    return nil;
}

@end
