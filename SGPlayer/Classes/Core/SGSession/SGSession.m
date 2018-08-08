//
//  SGSession.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGSession.h"
#import "SGCommonSource.h"
#import "SGAudioFFDecoder.h"
#import "SGVideoFFDecoder.h"
#import "SGVideoAVDecoder.h"
#import "SGMacro.h"
#import "SGTime.h"

@interface SGSession () <NSLocking, SGSourceDelegate, SGDecoderDelegate, SGOutputDelegate>

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, strong) SGSessionConfiguration * configuration;
@property (nonatomic, strong) NSLock * coreLock;

@end

@implementation SGSession

- (instancetype)initWithURL:(NSURL *)URL configuration:(SGSessionConfiguration *)configuration
{
    if (self = [super init])
    {
        self.URL = URL;
        self.configuration = configuration;
    }
    return self;
}

- (void)dealloc
{
    
}

#pragma mark - Interface

- (void)open
{
    [self lock];
    if (self.state != SGSessionStateNone)
    {
        [self unlock];
        return;
    }
    SGBasicBlock callback = [self setState:SGSessionStateOpening];
    [self unlock];
    callback();
    if (!self.configuration.source)
    {
        self.configuration.source = [[SGCommonSource alloc] init];
    }
    self.configuration.source.URL = self.URL;
    self.configuration.source.delegate = self;
    [self.configuration.source open];
}

- (void)read
{
    [self lock];
    if (self.state != SGSessionStateOpened)
    {
        [self unlock];
        return;
    }
    SGBasicBlock callback = [self setState:SGSessionStateReading];
    [self unlock];
    callback();
    [self.configuration.source read];
}

- (void)close
{
    [self lock];
    if (self.state == SGSessionStateClosed)
    {
        [self unlock];
        return;
    }
    SGBasicBlock callback = [self setState:SGSessionStateClosed];
    [self unlock];
    callback();
    [self.configuration.source close];
    [self.configuration.audioDecoder close];
    [self.configuration.videoDecoder close];
    [self.configuration.audioOutput close];
    [self.configuration.videoOutput close];
}

#pragma mark - Seek

- (BOOL)seekable
{
    [self lock];
    switch (self.state)
    {
        case SGSessionStateNone:
        case SGSessionStateOpening:
        case SGSessionStateOpened:
        case SGSessionStateClosed:
        case SGSessionStateFailed:
            [self unlock];
            return NO;
        case SGSessionStateReading:
        case SGSessionStateSeeking:
        case SGSessionStateFinished:
            break;
    }
    [self unlock];
    return self.configuration.source.seekable;
}

- (BOOL)seekableToTime:(CMTime)time
{
    if (CMTIME_IS_INVALID(time))
    {
        return NO;
    }
    return self.seekable;
}

- (BOOL)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL, CMTime))completionHandler
{
    if (![self seekableToTime:time])
    {
        return NO;
    }
    [self lock];
    if (self.state != SGSessionStateReading &&
        self.state != SGSessionStateSeeking &&
        self.state != SGSessionStateFinished)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGSessionStateSeeking];
    [self unlock];
    callback();
    SGWeakSelf
    [self.configuration.source seekToTime:time completionHandler:^(BOOL success, CMTime time) {
        SGStrongSelf
        [self.configuration.audioDecoder flush];
        [self.configuration.videoDecoder flush];
        [self.configuration.audioOutput flush];
        [self.configuration.videoOutput flush];
        [self lock];
        BOOL enable = NO;
        SGBasicBlock callback = ^{};
        if (self.state == SGSessionStateSeeking)
        {
            enable = YES;
            callback = [self setState:SGSessionStateReading];
        }
        [self unlock];
        if (enable)
        {
            if (completionHandler)
            {
                completionHandler(success, time);
            }
            callback();
        }
    }];
    return YES;
}

#pragma mark - Setter/Getter

- (SGBasicBlock)setState:(SGSessionState)state
{
    if (_state != state)
    {
        _state = state;
        return ^{
            [self.delegate sessionDidChangeState:self];
        };
    }
    return ^{};
}

- (CMTime)duration
{
    return self.configuration.source.duration;
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
    if (self.configuration.audioDecoder && self.configuration.audioOutput)
    {
        return CMTimeAdd(self.configuration.audioDecoder.duration, self.configuration.audioOutput.duration);
    }
    return kCMTimeZero;
}

- (CMTime)videoLoadedDuration
{
    if (self.configuration.videoDecoder && self.configuration.videoOutput)
    {
        return CMTimeAdd(self.configuration.videoDecoder.duration, self.configuration.videoOutput.duration);
    }
    return kCMTimeZero;
}

- (long long)audioLoadedSize
{
    return self.configuration.audioDecoder.size + self.configuration.audioOutput.size;
}

- (long long)videoLoadedSize
{
    return self.configuration.videoDecoder.size + self.configuration.videoOutput.size;
}

- (BOOL)audioEnable
{
    return self.configuration.audioDecoder != nil;
}

- (BOOL)videoEnable
{
    return self.configuration.videoDecoder != nil;
}

#pragma mark - Internal

- (void)setupDecoderIfNeeded
{
    if (self.configuration.audioDecoder && self.configuration.videoDecoder)
    {
        return;
    }
    for (SGStream * stream in self.configuration.source.streams)
    {
        switch (stream.mediaType)
        {
            case SGMediaTypeAudio:
            {
                if (!self.configuration.audioDecoder)
                {
                    SGAudioFFDecoder * audioDecoder = [[SGAudioFFDecoder alloc] init];
                    audioDecoder.delegate = self;
                    audioDecoder.index = stream.index;
                    audioDecoder.timebase = SGTimeValidate(stream.timebase, CMTimeMake(1, 44100));
                    audioDecoder.codecpar = stream.coreStream->codecpar;
                    if ([audioDecoder open])
                    {
                        self.configuration.audioDecoder = audioDecoder;
                    }
                }
            }
                break;
            case SGMediaTypeVideo:
            {
                if (!self.configuration.videoDecoder)
                {
                    Class codecClass = [SGVideoFFDecoder class];
                    if (self.configuration.hardwareDecodeEnableH264 &&
                        stream.coreStream->codecpar->codec_id == AV_CODEC_ID_H264)
                    {
                        codecClass = [SGVideoAVDecoder class];
                    }
                    SGAsyncDecoder * videoDecoder = [[codecClass alloc] init];
                    videoDecoder.delegate = self;
                    videoDecoder.index = stream.index;
                    videoDecoder.timebase = SGTimeValidate(stream.timebase, CMTimeMake(1, 25000));
                    videoDecoder.codecpar = stream.coreStream->codecpar;
                    if ([videoDecoder open])
                    {
                        self.configuration.videoDecoder = videoDecoder;
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
    if (self.configuration.audioOutput && self.configuration.audioDecoder)
    {
        self.configuration.audioOutput.delegate = self;
        [self.configuration.audioOutput open];
    }
    if (self.configuration.videoOutput && self.configuration.videoDecoder)
    {
        self.configuration.videoOutput.delegate = self;
        [self.configuration.videoOutput open];
    }
}

- (void)updateCapacity
{
    CMTime duration = kCMTimeZero;
    long long size = 0;
    
    if (self.configuration.audioDecoder && self.configuration.audioOutput)
    {
        duration = CMTimeAdd(self.configuration.audioDecoder.duration, self.configuration.audioOutput.duration);
        size = self.configuration.audioDecoder.size + self.configuration.audioOutput.size;
    }
    else if (self.configuration.videoDecoder && self.configuration.videoOutput)
    {
        duration = CMTimeAdd(self.configuration.videoDecoder.duration, self.configuration.videoOutput.duration);
        size = self.configuration.videoDecoder.size + self.configuration.videoOutput.size;
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
        [self.configuration.source pause];
    } else {
        [self.configuration.source resume];
    }
    [self.delegate sessionDidChangeCapacity:self];
}

#pragma mark - SGSourceDelegate

- (void)sourceDidChangeState:(id <SGSource>)source
{
    [self lock];
    SGBasicBlock callback = ^{};
    switch (source.state)
    {
        case SGSourceStateOpened:
        {
            [self setupDecoderIfNeeded];
            [self setupOutputIfNeeded];
            callback = [self setState:SGSessionStateOpened];
        }
            break;
        case SGSourceStateFinished:
        {
            callback = [self setState:SGSessionStateFinished];
        }
            break;
        case SGSourceStateFailed:
        {
            _error = source.error;
            callback = [self setState:SGSessionStateFailed];
        }
            break;
        default:
            break;
    }
    [self unlock];
    callback();
}

- (void)source:(id <SGSource>)source hasNewPacket:(SGPacket *)packet
{
    if (packet.index == self.configuration.audioDecoder.index)
    {
        [packet fillWithTimebase:self.configuration.audioDecoder.timebase];
        [self.configuration.audioDecoder putPacket:packet];
    }
    else if (packet.index == self.configuration.videoDecoder.index)
    {
        [packet fillWithTimebase:self.configuration.videoDecoder.timebase];
        [self.configuration.videoDecoder putPacket:packet];
    }
}

#pragma mark - SGDecoderDelegate

- (void)decoderDidChangeState:(id <SGDecoder>)decoder
{
    
}

- (void)decoderDidChangeCapacity:(id <SGDecoder>)decoder
{
    [self updateCapacity];
}

- (void)decoder:(id <SGDecoder>)decoder hasNewFrame:(__kindof SGFrame *)frame
{
    if (decoder == self.configuration.audioDecoder)
    {
        [self.configuration.audioOutput putFrame:frame];
    }
    else if (decoder == self.configuration.videoDecoder)
    {
        [self.configuration.videoOutput putFrame:frame];
    }
}

#pragma mark - SGOutputDelegate

- (void)outputDidChangeCapacity:(id <SGOutput>)output
{
    if (output == self.configuration.audioOutput)
    {
        if (self.configuration.audioOutput.count >= self.configuration.audioOutput.maxCount) {
            [self.configuration.audioDecoder pause];
        } else {
            [self.configuration.audioDecoder resume];
        }
    }
    else if (output == self.configuration.videoOutput)
    {
        if (self.configuration.videoOutput.count >= self.configuration.videoOutput.maxCount) {
            [self.configuration.videoDecoder pause];
        } else {
            [self.configuration.videoDecoder resume];
        }
    }
    [self updateCapacity];
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
