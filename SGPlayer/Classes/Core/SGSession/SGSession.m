//
//  SGSession.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGSession.h"
#import "SGFFmpeg.h"
#import "SGCommonSource.h"
#import "SGAudioFFDecoder.h"
#import "SGVideoFFDecoder.h"
#import "SGVideoAVDecoder.h"
#import "SGMacro.h"
#import "SGTime.h"

@interface SGSession () <SGSourceDelegate, SGDecoderDelegate, SGOutputDelegate>

@property (nonatomic, strong) dispatch_queue_t delegateQueue;

@property (nonatomic, strong) id <SGSource> source;
@property (nonatomic, strong) id <SGDecoder> audioDecoder;
@property (nonatomic, strong) id <SGDecoder> videoDecoder;
@property (nonatomic, strong) id <SGOutput> audioOutput;
@property (nonatomic, strong) id <SGOutput> videoOutput;
@property (nonatomic, strong) SGTimeSynchronizer * timeSynchronizer;

@end

@implementation SGSession

@synthesize state = _state;

- (instancetype)init
{
    if (self = [super init])
    {
        [SGFFmpeg setupIfNeeded];
        self.delegateQueue = dispatch_queue_create("SGSession-Delegate-Queue", DISPATCH_QUEUE_SERIAL);
        self.state = SGSessionStateIdle;
    }
    return self;
}

#pragma mark - Streams

- (void)open
{
    if (self.state != SGSessionStateIdle)
    {
        return;
    }
    self.state = SGSessionStateOpening;
    self.source = [[SGCommonSource alloc] init];
    self.source.URL = self.URL;
    self.source.delegate = self;
    [self.source open];
}

- (void)read
{
    if (self.state != SGSessionStateOpened)
    {
        return;
    }
    self.state = SGSessionStateReading;
    [self.source read];
}

- (void)close
{
    if (self.state == SGSessionStateClosed)
    {
        return;
    }
    self.state = SGSessionStateClosed;
    [self.source close];
    [self.audioDecoder stopDecoding];
    [self.videoDecoder stopDecoding];
    [self.audioOutput stop];
    [self.videoOutput stop];
}

#pragma mark - Seek

- (BOOL)seekable
{
    switch (self.state)
    {
        case SGSessionStateIdle:
        case SGSessionStateOpening:
        case SGSessionStateOpened:
        case SGSessionStateClosed:
        case SGSessionStateFailed:
            return NO;
        case SGSessionStateFinished:
        case SGSessionStateReading:
            break;
    }
    return self.source.seekable;
}

- (BOOL)seekableToTime:(CMTime)time
{
    if (CMTIME_IS_INVALID(time))
    {
        return NO;
    }
    return self.seekable;
}

- (BOOL)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler
{
    if (![self seekableToTime:time])
    {
        return NO;
    }
    if (self.state == SGSessionStateFinished)
    {
        self.state = SGSessionStateReading;
    }
    SGWeakSelf
    [self.source seekToTime:time completionHandler:^(BOOL success) {
        SGStrongSelf
        [strongSelf.audioDecoder flush];
        [strongSelf.videoDecoder flush];
        [strongSelf.audioOutput flush];
        [strongSelf.videoOutput flush];
        if (completionHandler)
        {
            completionHandler(success);
        }
    }];
    return YES;
}

#pragma mark - Setter/Getter

- (CMTime)duration
{
    return self.source.duration;
}

- (CMTime)currentTime
{
    return self.timeSynchronizer.position;
}

- (CMTime)loadedDuration
{
    return [self loadedDurationWithMainMediaType:SGMediaTypeAudio];
}

- (CMTime)loadedDurationWithMainMediaType:(SGMediaType)mainMediaType
{
    if (self.audioEnable && !self.videoEnable)
    {
        return self.audioLoadedDuration;
    }
    else if (!self.audioEnable && self.videoEnable)
    {
        return self.videoLoadedDuration;
    }
    else if (self.audioEnable && self.videoEnable)
    {
        if (mainMediaType == SGMediaTypeAudio)
        {
            return self.audioLoadedDuration;
        }
        else if (mainMediaType == SGMediaTypeVideo)
        {
            return self.videoLoadedDuration;
        }
    }
    return kCMTimeZero;
}

- (long long)loadedSize
{
    return [self loadedSizeWithMainMediaType:SGMediaTypeAudio];
}

- (long long)loadedSizeWithMainMediaType:(SGMediaType)mainMediaType
{
    if (self.audioEnable && !self.videoEnable)
    {
        return self.audioLoadedSize;
    }
    else if (!self.audioEnable && self.videoEnable)
    {
        return self.videoLoadedSize;
    }
    else if (self.audioEnable && self.videoEnable)
    {
        if (mainMediaType == SGMediaTypeAudio)
        {
            return self.audioLoadedSize;
        }
        else if (mainMediaType == SGMediaTypeVideo)
        {
            return self.videoLoadedSize;
        }
    }
    return 0;
}

- (CMTime)audioLoadedDuration
{
    if (self.audioDecoder && self.audioOutput)
    {
        return CMTimeAdd(self.audioDecoder.duration, self.audioOutput.duration);
    }
    return kCMTimeZero;
}

- (CMTime)videoLoadedDuration
{
    if (self.videoDecoder && self.videoOutput)
    {
        return CMTimeAdd(self.videoDecoder.duration, self.videoOutput.duration);
    }
    return kCMTimeZero;
}

- (long long)audioLoadedSize
{
    return self.audioDecoder.size + self.audioOutput.size;
}

- (long long)videoLoadedSize
{
    return self.videoDecoder.size + self.videoOutput.size;
}

- (BOOL)audioEnable
{
    return self.audioDecoder != nil;
}

- (BOOL)videoEnable
{
    return self.videoDecoder != nil;
}

- (void)setState:(SGSessionState)state
{
    if (_state != state)
    {
        _state = state;
        if ([self.delegate respondsToSelector:@selector(sessionDidChangeState:)])
        {
            dispatch_async(self.delegateQueue, ^{
                [self.delegate sessionDidChangeState:self];
            });
        }
    }
}

#pragma mark - Internal

- (void)setupDecoderIfNeeded
{
    for (SGStream * stream in self.source.streams)
    {
        switch (stream.mediaType)
        {
            case SGMediaTypeAudio:
            {
                if (!self.audioDecoder)
                {
                    SGAudioFFDecoder * audioDecoder = [[SGAudioFFDecoder alloc] init];
                    audioDecoder.delegate = self;
                    audioDecoder.index = stream.index;
                    audioDecoder.timebase = SGTimeValidate(stream.timebase, CMTimeMake(1, 44100));
                    audioDecoder.codecpar = stream.coreStream->codecpar;
                    if ([audioDecoder startDecoding])
                    {
                        self.audioDecoder = audioDecoder;
                    }
                }
            }
                break;
            case SGMediaTypeVideo:
            {
                if (!self.videoDecoder)
                {
                    Class codecClass = [SGVideoFFDecoder class];
                    if (self.configuration.enableVideoToolBox && stream.coreStream->codecpar->codec_id == AV_CODEC_ID_H264)
                    {
                        codecClass = [SGVideoAVDecoder class];
                    }
                    SGAsyncDecoder * videoDecoder = [[codecClass alloc] init];
                    videoDecoder.delegate = self;
                    videoDecoder.index = stream.index;
                    videoDecoder.timebase = SGTimeValidate(stream.timebase, CMTimeMake(1, 25000));
                    videoDecoder.codecpar = stream.coreStream->codecpar;
                    if ([videoDecoder startDecoding])
                    {
                        self.videoDecoder = videoDecoder;
                    }
                }
            }
                break;
            default:
                break;
        }
    }
}

- (void)setupOutputIfNeeded
{
    if (!self.timeSynchronizer)
    {
        self.timeSynchronizer = [[SGTimeSynchronizer alloc] init];
    }
    if (!self.audioOutput && self.audioDecoder)
    {
        self.audioOutput = self.configuration.audioOutput;
        self.audioOutput.delegate = self;
        self.audioOutput.timeSynchronizer = self.timeSynchronizer;
        [self.audioOutput start];
    }
    if (!self.videoOutput && self.videoDecoder)
    {
        self.videoOutput = self.configuration.videoOutput;
        self.videoOutput.delegate = self;
        self.videoOutput.timeSynchronizer = self.timeSynchronizer;
        [self.videoOutput start];
    }
}

- (void)updateCapacity
{
    CMTime duration = kCMTimeZero;
    long long size = 0;
    
    if (self.audioDecoder && self.audioOutput)
    {
        duration = CMTimeAdd(self.audioDecoder.duration, self.audioOutput.duration);
        size = self.audioDecoder.size + self.audioOutput.size;
    }
    else if (self.videoDecoder && self.videoOutput)
    {
        duration = CMTimeAdd(self.videoDecoder.duration, self.videoOutput.duration);
        size = self.videoDecoder.size + self.videoOutput.size;
    }
    else
    {
        return;
    }
    
    BOOL shouldPaused = NO;
    if (size > 15 * 1024 * 1024)
    {
        shouldPaused = YES;
    }
    else if (CMTimeCompare(duration, CMTimeMake(10, 1)) > 0)
    {
        shouldPaused = YES;
    }
    if (shouldPaused) {
        [self.source pause];
    } else {
        [self.source resume];
    }
    if ([self.delegate respondsToSelector:@selector(sessionDidChangeCapacity:)])
    {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate sessionDidChangeCapacity:self];
        });
    }
}

#pragma mark - SGSourceDelegate

- (void)sourceDidChangeState:(id <SGSource>)source
{
    switch (source.state)
    {
        case SGSourceStateOpened:
        {
            [self setupDecoderIfNeeded];
            [self setupOutputIfNeeded];
            self.state = SGSessionStateOpened;
        }
            break;
        case SGSourceStateFinished:
        {
            self.state = SGSessionStateFinished;
        }
            break;
        case SGSourceStateFailed:
        {
            _error = source.error;
            self.state = SGSessionStateFailed;
        }
            break;
        default:
            break;
    }
}

- (void)source:(id <SGSource>)source hasNewPacket:(SGPacket *)packet
{
    if (packet.index == self.audioDecoder.index)
    {
        [packet fillWithTimebase:self.audioDecoder.timebase];
        [self.audioDecoder putPacket:packet];
    }
    else if (packet.index == self.videoDecoder.index)
    {
        [packet fillWithTimebase:self.videoDecoder.timebase];
        [self.videoDecoder putPacket:packet];
    }
}

#pragma mark - SGDecoderDelegate

- (void)decoderDidChangeCapacity:(id <SGDecoder>)decoder
{
    [self updateCapacity];
}

- (void)decoder:(id <SGDecoder>)decoder hasNewFrame:(__kindof SGFrame *)frame
{
    if (decoder == self.audioDecoder)
    {
        [self.audioOutput putFrame:frame];
    }
    else if (decoder == self.videoDecoder)
    {
        [self.videoOutput putFrame:frame];
    }
}

#pragma mark - SGOutputDelegate

- (void)outputDidChangeCapacity:(id <SGOutput>)output
{
    if (output == self.audioOutput)
    {
        if (self.audioOutput.count >= self.audioOutput.maxCount) {
            [self.audioDecoder pauseDecoding];
        } else {
            [self.audioDecoder resumeDecoding];
        }
    }
    else if (output == self.videoOutput)
    {
        if (self.videoOutput.count >= self.videoOutput.maxCount) {
            [self.videoDecoder pauseDecoding];
        } else {
            [self.videoDecoder resumeDecoding];
        }
    }
    [self updateCapacity];
}

@end
