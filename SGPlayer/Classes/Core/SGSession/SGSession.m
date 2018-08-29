//
//  SGSession.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGSession.h"
#import "SGFFmpeg.h"
#import "SGMacro.h"
#import "SGError.h"
#import "SGTime.h"

@interface SGSession () <NSLocking, SGSourceDelegate, SGDecoderDelegate, SGOutputDelegate>

@property (nonatomic, strong) SGSessionConfiguration * configuration;
@property (nonatomic, strong) NSLock * coreLock;

@end

@implementation SGSession

- (instancetype)initWithConfiguration:(SGSessionConfiguration *)configuration
{
    if (self = [super init])
    {
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
    SGFFmpegSetupIfNeeded();
    [self lock];
    if (self.state != SGSessionStateNone)
    {
        [self unlock];
        return;
    }
    SGBasicBlock callback = [self setState:SGSessionStateOpening];
    [self unlock];
    callback();
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

#pragma mark - Setter & Getter

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

 - (NSDictionary *)metadata
{
    return self.configuration.source.metadata;
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

- (BOOL)empty
{
    return [self emptyWithMainMediaType:SGMediaTypeAudio];
}

- (BOOL)emptyWithMainMediaType:(SGMediaType)mainMediaType
{
    if (self.audioEnable && !self.videoEnable)
    {
        return self.audioEmpty;
    }
    else if (!self.audioEnable && self.videoEnable)
    {
        return self.videoEmpty;
    }
    else if (self.audioEnable && self.videoEnable)
    {
        if (mainMediaType == SGMediaTypeAudio)
        {
            return self.audioEmpty;
        }
        else if (mainMediaType == SGMediaTypeVideo)
        {
            return self.videoEmpty;
        }
    }
    return YES;
}

- (BOOL)audioEnable
{
    return self.configuration.source.audioEnable;
}

- (BOOL)videoEnable
{
    return self.configuration.source.videoEnable;
}

- (BOOL)audioEmpty
{
    if (self.audioEnable && self.configuration.audioOutput)
    {
        return self.configuration.audioDecoder.empty && self.configuration.audioOutput.empty;
    }
    return YES;
}

- (BOOL)videoEmpty
{
    if (self.videoEnable && self.configuration.videoOutput)
    {
        return self.configuration.videoDecoder.empty && self.configuration.videoOutput.empty;
    }
    return YES;
}

- (CMTime)audioLoadedDuration
{
    if (self.audioEnable && self.configuration.audioOutput)
    {
        return CMTimeAdd(self.configuration.audioDecoder.duration, self.configuration.audioOutput.duration);
    }
    return kCMTimeZero;
}

- (CMTime)videoLoadedDuration
{
    if (self.videoEnable && self.configuration.videoOutput)
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

#pragma mark - Internal

- (void)updateCapacity
{
    CMTime duration = kCMTimeZero;
    long long size = 0;
    
    if (self.audioEnable && self.configuration.audioOutput)
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
            if (!self.audioEnable && !self.videoEnable)
            {
                _error = SGECreateError(@"", SGErrorCodeNoValidTrackToPlay);
                callback = [self setState:SGSessionStateFailed];
            }
            else
            {
                if (self.audioEnable)
                {
                    self.configuration.audioDecoder.delegate = self;
                    [self.configuration.audioDecoder open];
                    self.configuration.audioOutput.enable = YES;
                    self.configuration.audioOutput.key = YES;
                    self.configuration.audioOutput.delegate = self;
                    [self.configuration.audioOutput open];
                }
                if (self.videoEnable)
                {
                    self.configuration.videoDecoder.delegate = self;
                    [self.configuration.videoDecoder open];
                    self.configuration.videoOutput.enable = YES;
                    self.configuration.videoOutput.key = !self.audioEnable;
                    self.configuration.videoOutput.delegate = self;
                    [self.configuration.videoOutput open];
                }
                callback = [self setState:SGSessionStateOpened];
            }
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
    switch (packet.mediaType)
    {
        case SGMediaTypeAudio:
            [self.configuration.audioDecoder putPacket:packet];
            break;
        case SGMediaTypeVideo:
            [self.configuration.videoDecoder putPacket:packet];
            break;
        default:
            break;
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
