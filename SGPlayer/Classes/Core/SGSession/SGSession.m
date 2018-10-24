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

@interface SGSession () <NSLocking, SGFrameOutputDelegate, SGRendererDelegate>

@property (nonatomic, strong) SGSessionConfiguration * configuration;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, assign) NSUInteger seekingToken;

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

- (void)start
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
    [self.configuration.source start];
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
    [self.configuration.audioOutput close];
    [self.configuration.videoOutput close];
}

#pragma mark - Seek

- (BOOL)seeking
{
    [self lock];
    BOOL ret = self.seekingToken != 0;
    [self unlock];
    return ret;
}

- (BOOL)seekable
{
    return !self.configuration.source.seekable;
}

- (BOOL)seekToTime:(CMTime)time completionHandler:(void (^)(CMTime, NSError *))completionHandler
{
    if (![self seekable])
    {
        return NO;
    }
    [self lock];
    if (self.state != SGSessionStateReading &&
        self.state != SGSessionStateFinished)
    {
        [self unlock];
        return NO;
    }
    self.seekingToken++;
    NSInteger seekingToken = self.seekingToken;
    [self unlock];
    SGWeakSelf
    [self.configuration.source seekToTime:time completionHandler:^(CMTime time, NSError * error) {
        SGStrongSelf
        [self lock];
        if (seekingToken != self.seekingToken)
        {
            [self unlock];
            return;
        }
        self.seekingToken = 0;
        [self unlock];
        [self.configuration.audioOutput flush];
        [self.configuration.videoOutput flush];
        if (completionHandler)
        {
            completionHandler(time, error);
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
    return self.configuration.source.audioStreams.count > 0;
}

- (BOOL)videoEnable
{
    return self.configuration.source.videoStreams.count > 0;
}

- (BOOL)audioEmpty
{
    if (self.audioEnable && self.configuration.audioOutput)
    {
        NSUInteger sourceCount = 0;
        [self.configuration.source duratioin:NULL size:NULL count:&sourceCount stream:self.configuration.source.audioStreams.firstObject];
        
        NSUInteger outputCount = 0;
        [self.configuration.audioOutput duratioin:NULL size:NULL count:&outputCount];
        
        return sourceCount == 0 && outputCount == 0;
    }
    return YES;
}

- (BOOL)videoEmpty
{
    if (self.videoEnable && self.configuration.videoOutput)
    {
        NSUInteger sourceCount = 0;
        [self.configuration.source duratioin:NULL size:NULL count:&sourceCount stream:self.configuration.source.videoStreams.firstObject];
        
        NSUInteger outputCount = 0;
        [self.configuration.videoOutput duratioin:NULL size:NULL count:&outputCount];
        
        return sourceCount == 0 && outputCount == 0;
    }
    return YES;
}

- (CMTime)audioLoadedDuration
{
    if (self.audioEnable && self.configuration.audioOutput)
    {
        CMTime sourceDuration = kCMTimeZero;
        [self.configuration.source duratioin:&sourceDuration size:NULL count:NULL stream:self.configuration.source.audioStreams.firstObject];
        
        CMTime outputDuration = kCMTimeZero;
        [self.configuration.audioOutput duratioin:&outputDuration size:NULL count:NULL];
        
        return CMTimeAdd(sourceDuration, outputDuration);
    }
    return kCMTimeZero;
}

- (CMTime)videoLoadedDuration
{
    if (self.videoEnable && self.configuration.videoOutput)
    {
        CMTime sourceDuration = kCMTimeZero;
        [self.configuration.source duratioin:&sourceDuration size:NULL count:NULL stream:self.configuration.source.videoStreams.firstObject];
        
        CMTime outputDuration = kCMTimeZero;
        [self.configuration.videoOutput duratioin:&outputDuration size:NULL count:NULL];
        
        return CMTimeAdd(sourceDuration, outputDuration);
    }
    return kCMTimeZero;
}

- (long long)audioLoadedSize
{
    int64_t sourceSize = 0;
    [self.configuration.source duratioin:NULL size:&sourceSize count:NULL stream:self.configuration.source.audioStreams.firstObject];
    
    int64_t outputSzie = 0;
    [self.configuration.audioOutput duratioin:NULL size:&outputSzie count:NULL];
    
    return sourceSize + outputSzie;
}

- (long long)videoLoadedSize
{
    int64_t sourceSize = 0;
    [self.configuration.source duratioin:NULL size:&sourceSize count:NULL stream:self.configuration.source.videoStreams.firstObject];
    
    int64_t outputSzie = 0;
    [self.configuration.videoOutput duratioin:NULL size:&outputSzie count:NULL];
    
    return sourceSize + outputSzie;
}

#pragma mark - SGFrameOutputDelegate

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeState:(SGFrameOutputState)state
{
    switch (state)
    {
        case SGFrameOutputStateOpened:
        {
            [self lock];
            if (self.audioEnable)
            {
                self.configuration.audioOutput.enable = YES;
                self.configuration.audioOutput.key = YES;
                self.configuration.audioOutput.delegate = self;
                [self.configuration.audioOutput open];
            }
            if (self.videoEnable)
            {
                self.configuration.videoOutput.enable = YES;
                self.configuration.videoOutput.key = !self.audioEnable;
                self.configuration.videoOutput.delegate = self;
                [self.configuration.videoOutput open];
            }
            SGBasicBlock callback = [self setState:SGSessionStateOpened];
            [self unlock];
            callback();
        }
            break;
        case SGFrameOutputStateReading:
        {
            [self lock];
            SGBasicBlock callback = [self setState:SGSessionStateReading];
            [self unlock];
            callback();
        }
            break;
        case SGFrameOutputStateFinished:
        {
            [self lock];
            SGBasicBlock callback = [self setState:SGSessionStateFinished];
            [self unlock];
            callback();
        }
            break;
        case SGFrameOutputStateFailed:
        {
            _error = frameOutput.error;
            [self lock];
            SGBasicBlock callback = [self setState:SGSessionStateFailed];
            [self unlock];
            callback();
        }
            break;
        default:
            break;
    }
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeDuration:(CMTime)duration size:(int64_t)size count:(NSUInteger)count stream:(SGStream *)stream
{
    [self.delegate sessionDidChangeCapacity:self];
}

- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(SGFrame *)frame
{
    if (frame.stream.type == SGMediaTypeAudio)
    {
        [self.configuration.audioOutput putFrame:frame];
    }
    else if (frame.stream.type == SGMediaTypeVideo)
    {
        [self.configuration.videoOutput putFrame:frame];
    }
}

#pragma mark - SGRendererDelegate

- (void)outputDidChangeCapacity:(id <SGRenderer>)output
{
    if (output == self.configuration.audioOutput)
    {
        if (self.configuration.audioOutput.enough) {
            [self.configuration.source pause:self.configuration.source.audioStreams];
        } else {
            [self.configuration.source resume:self.configuration.source.audioStreams];
        }
    }
    else if (output == self.configuration.videoOutput)
    {
        if (self.configuration.videoOutput.enough) {
            [self.configuration.source pause:self.configuration.source.videoStreams];
        } else {
            [self.configuration.source resume:self.configuration.source.videoStreams];
        }
    }
    [self.delegate sessionDidChangeCapacity:self];
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
