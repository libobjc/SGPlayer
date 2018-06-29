//
//  SGFFSession.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFSession.h"
#import "SGFFFormatContext.h"
#import "SGFFAudioFFDecoder.h"
#import "SGFFVideoFFDecoder.h"
#import "SGFFVideoAVDecoder.h"
#import "SGPlayerMacro.h"
#import "SGFFTime.h"
#import "SGFFLog.h"

@interface SGFFSession () <SGFFSourceDelegate, SGFFDecoderDelegate, SGFFOutputDelegate>

@property (nonatomic, strong) dispatch_queue_t delegateQueue;

@property (nonatomic, strong) id <SGFFSource> source;
@property (nonatomic, strong) id <SGFFDecoder> audioDecoder;
@property (nonatomic, strong) id <SGFFDecoder> videoDecoder;
@property (nonatomic, strong) id <SGFFOutput> audioOutput;
@property (nonatomic, strong) id <SGFFOutput> videoOutput;
@property (nonatomic, strong) SGFFTimeSynchronizer * timeSynchronizer;

@end

@implementation SGFFSession

@synthesize state = _state;

- (instancetype)init
{
    if (self = [super init])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            av_log_set_callback(SGFFLogCallback);
            av_register_all();
            avformat_network_init();
        });
        self.delegateQueue = dispatch_queue_create("SGFFSession-Delegate-Queue", DISPATCH_QUEUE_SERIAL);
        self.state = SGFFSessionStateIdle;
    }
    return self;
}

#pragma mark - Streams

- (void)openStreams
{
    if (self.state != SGFFSessionStateIdle)
    {
        return;
    }
    self.state = SGFFSessionStateOpening;
    self.timeSynchronizer = [[SGFFTimeSynchronizer alloc] init];
    self.audioOutput = self.configuration.audioOutput;
    self.videoOutput = self.configuration.videoOutput;
    self.audioOutput.timeSynchronizer = self.timeSynchronizer;
    self.videoOutput.timeSynchronizer = self.timeSynchronizer;
    self.audioOutput.delegate = self;
    self.videoOutput.delegate = self;
    self.source = [[SGFFFormatContext alloc] init];
    self.source.URL = self.URL;
    self.source.delegate = self;
    [self.source openStreams];
}

- (void)startReading
{
    if (self.state != SGFFSessionStateOpened)
    {
        return;
    }
    self.state = SGFFSessionStateReading;
    [self.source startReading];
}

- (void)closeStreams
{
    if (self.state == SGFFSessionStateClosed)
    {
        return;
    }
    self.state = SGFFSessionStateClosed;
    [self.source stopReading];
    [self.audioDecoder stopDecoding];
    [self.videoDecoder stopDecoding];
    [self.audioOutput stop];
    [self.videoOutput stop];
}

#pragma mark - Seek

- (BOOL)seekEnable
{
    return self.source.seekable;
}

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler
{
    switch (self.state)
    {
        case SGFFSessionStateIdle:
        case SGFFSessionStateOpening:
        case SGFFSessionStateOpened:
        case SGFFSessionStateClosed:
        case SGFFSessionStateFailed:
            if (completionHandler)
            {
                completionHandler(NO);
            }
            return;
        case SGFFSessionStateFinished:
            self.state = SGFFSessionStateReading;
            break;
        case SGFFSessionStateReading:
            break;
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

- (void)setState:(SGFFSessionState)state
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

#pragma mark - Capacity

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
        [self.source pauseReading];
    } else {
        [self.source resumeReading];
    }
    if ([self.delegate respondsToSelector:@selector(sessionDidChangeCapacity:)])
    {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate sessionDidChangeCapacity:self];
        });
    }
}

#pragma mark - SGFFSourceDelegate

- (void)source:(id <SGFFSource>)source hasNewPacket:(SGFFPacket *)packet
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

- (void)sourceDidOpened:(id <SGFFSource>)source
{
    for (SGFFStream * stream in source.streams)
    {
        switch (stream.mediaType)
        {
            case SGMediaTypeAudio:
            {
                if (!self.audioDecoder)
                {
                    SGFFAudioFFDecoder * audioDecoder = [[SGFFAudioFFDecoder alloc] init];
                    audioDecoder.index = stream.index;
                    audioDecoder.timebase = SGFFTimeValidate(stream.timebase, CMTimeMake(1, 44100));
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
                    Class codecClass = [SGFFVideoFFDecoder class];
                    if (self.configuration.enableVideoToolBox && stream.coreStream->codecpar->codec_id == AV_CODEC_ID_H264)
                    {
                        codecClass = [SGFFVideoAVDecoder class];
                    }
                    SGFFAsyncDecoder * videoDecoder = [[codecClass alloc] init];
                    videoDecoder.index = stream.index;
                    videoDecoder.timebase = SGFFTimeValidate(stream.timebase, CMTimeMake(1, 25000));
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
    self.audioDecoder.delegate = self;
    self.videoDecoder.delegate = self;
    [self.audioOutput start];
    [self.videoOutput start];
    self.state = SGFFSessionStateOpened;
}

- (void)sourceDidFailed:(id <SGFFSource>)source
{
    _error = source.error;
    self.state = SGFFSessionStateFailed;
}

- (void)sourceDidFinished:(id<SGFFSource>)source
{
    self.state = SGFFSessionStateFinished;
}

#pragma mark - SGFFDecoderDelegate

- (void)decoderDidChangeCapacity:(id <SGFFDecoder>)decoder
{
    [self updateCapacity];
}

- (void)decoder:(id <SGFFDecoder>)decoder hasNewFrame:(__kindof SGFFFrame *)frame
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

#pragma mark - SGFFOutputDelegate

- (void)outputDidChangeCapacity:(id <SGFFOutput>)output
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
