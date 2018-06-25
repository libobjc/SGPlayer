//
//  SGFFSession.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFSession.h"
#import "SGFFFormatContext.h"
#import "SGFFAudioAVCodec.h"
#import "SGFFVideoAVCodec.h"
#import "SGFFVideoVTBCodec.h"
#import "SGPlayerMacro.h"
#import "SGFFTime.h"
#import "SGFFLog.h"

@interface SGFFSession () <SGFFSourceDelegate, SGFFCodecDelegate, SGFFOutputDelegate>

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, weak) id <SGFFSessionDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) SGFFSessionConfiguration * configuration;

@property (nonatomic, assign) SGFFSessionState state;
@property (nonatomic, copy) NSError * error;

@property (nonatomic, strong) id <SGFFSource> source;
@property (nonatomic, strong) id <SGFFCodec> audioCodec;
@property (nonatomic, strong) id <SGFFCodec> videoCodec;
@property (nonatomic, strong) id <SGFFOutput> audioOutput;
@property (nonatomic, strong) id <SGFFOutput> videoOutput;
@property (nonatomic, strong) SGFFTimeSynchronizer * timeSynchronizer;

@end

@implementation SGFFSession

+ (instancetype)sessionWithContentURL:(NSURL *)contentURL
                             delegate:(id <SGFFSessionDelegate>)delegate
                        configuration:(SGFFSessionConfiguration *)configuration
{
    return [[self alloc] initWithContentURL:contentURL
                                   delegate:delegate
                              configuration:configuration];
}

- (instancetype)initWithContentURL:(NSURL *)contentURL
                          delegate:(id <SGFFSessionDelegate>)delegate
                     configuration:(SGFFSessionConfiguration *)configuration
{
    if (self = [super init])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            av_log_set_callback(SGFFLogCallback);
            av_register_all();
            avformat_network_init();
        });
        self.contentURL = contentURL;
        self.delegate = delegate;
        self.delegateQueue = dispatch_queue_create("SGFFSession-Delegate-Queue", DISPATCH_QUEUE_SERIAL);
        self.configuration = configuration;
        self.audioOutput = self.configuration.audioOutput;
        self.videoOutput = self.configuration.videoOutput;
        self.state = SGFFSessionStateIdle;
    }
    return self;
}

- (void)open
{
    self.state = SGFFSessionStateReading;
    self.source = [[SGFFFormatContext alloc] initWithContentURL:self.contentURL delegate:self];
    [self.source open];
}

- (void)read
{
    self.state = SGFFSessionStateReading;
    [self.source read];
}

- (void)close
{
    self.state = SGFFSessionStateClosed;
    [self.source close];
    [self.audioCodec close];
    [self.videoCodec close];
    [self.audioOutput close];
    [self.videoOutput close];
}

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler
{
    switch (self.state)
    {
        case SGFFSessionStateIdle:
        case SGFFSessionStateClosed:
        case SGFFSessionStateFailed:
            return;
        case SGFFSessionStateFinished:
            self.state = SGFFSessionStateReading;
            break;
        case SGFFSessionStateOpened:
        case SGFFSessionStateReading:
            break;
    }
    SGWeakSelf
    [self.source seekToTime:time completionHandler:^(BOOL success) {
        SGStrongSelf
        [self.audioCodec flush];
        [self.videoCodec flush];
        [self.audioOutput flush];
        [self.videoOutput flush];
        [strongSelf.timeSynchronizer flush];;
        [strongSelf.configuration.videoOutput flush];
        if (completionHandler)
        {
            completionHandler(success);
        }
    }];
}

- (void)updateCapacity
{
    CMTime duration = kCMTimeZero;
    long long size = 0;
    
    if (self.audioCodec && self.audioOutput)
    {
        duration = CMTimeAdd(self.audioCodec.duration, self.audioOutput.duration);
        size = self.audioCodec.size + self.audioOutput.size;
    }
    else if (self.videoCodec && self.videoOutput)
    {
        duration = CMTimeAdd(self.videoCodec.duration, self.videoOutput.duration);
        size = self.videoCodec.size + self.videoOutput.size;
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
    if ([self.delegate respondsToSelector:@selector(sessionDidChangeCapacity:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate sessionDidChangeCapacity:self];
        });
    }
}

#pragma mark - Setter/Getter

- (CMTime)duration
{
    return self.source.duration;
}

- (CMTime)loadedDuration
{
    if (self.audioCodec && self.audioOutput)
    {
        return CMTimeAdd(self.audioCodec.duration, self.audioOutput.duration);
    }
    else if (self.videoCodec && self.videoOutput)
    {
        return CMTimeAdd(self.videoCodec.duration, self.videoOutput.duration);
    }
    return kCMTimeZero;
}

- (long long)loadedSize
{
    return self.audioCodec.size + self.audioOutput.size + self.videoCodec.size + self.videoOutput.size;
}

- (BOOL)videoEnable
{
    return self.videoCodec != nil;
}

- (BOOL)audioEnable
{
    return self.audioCodec != nil;
}

- (BOOL)seekEnable
{
    return self.source.seekable;
}

#pragma mark - SGFFSourceDelegate

- (void)source:(id <SGFFSource>)source hasNewPacket:(SGFFPacket *)packet
{
    if (packet.index == self.audioCodec.index)
    {
        [packet fillWithTimebase:self.audioCodec.timebase];
        [self.audioCodec putPacket:packet];
    }
    else if (packet.index == self.videoCodec.index)
    {
        [packet fillWithTimebase:self.videoCodec.timebase];
        [self.videoCodec putPacket:packet];
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
                if (!self.audioCodec)
                {
                    SGFFAudioAVCodec * audioCodec = [[SGFFAudioAVCodec alloc] init];
                    audioCodec.index = stream.index;
                    audioCodec.timebase = SGFFTimeValidate(stream.timebase, CMTimeMake(1, 44100));
                    audioCodec.codecpar = stream.coreStream->codecpar;
                    if ([audioCodec open])
                    {
                        self.audioCodec = audioCodec;
                    }
                }
            }
                break;
            case SGMediaTypeVideo:
            {
                if (!self.videoCodec)
                {
                    Class codecClass = [SGFFVideoAVCodec class];
                    if (self.configuration.enableVideoToolBox && stream.coreStream->codecpar->codec_id == AV_CODEC_ID_H264)
                    {
                        codecClass = [SGFFVideoVTBCodec class];
                    }
                    SGFFAsyncCodec * videoCodec = [[codecClass alloc] init];
                    videoCodec.index = stream.index;
                    videoCodec.timebase = SGFFTimeValidate(stream.timebase, CMTimeMake(1, 25000));
                    videoCodec.codecpar = stream.coreStream->codecpar;
                    if ([videoCodec open])
                    {
                        self.videoCodec = videoCodec;
                    }
                }
            }
                break;
            default:
                break;
        }
    }

    self.audioCodec.delegate = self;
    self.videoCodec.delegate = self;
    self.timeSynchronizer = [[SGFFTimeSynchronizer alloc] init];
    self.configuration.audioOutput.timeSynchronizer = self.timeSynchronizer;
    self.configuration.videoOutput.timeSynchronizer = self.timeSynchronizer;

    self.state = SGFFSessionStateOpened;
    if ([self.delegate respondsToSelector:@selector(sessionDidOpened:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate sessionDidOpened:self];
        });
    }
}

- (void)sourceDidFailed:(id <SGFFSource>)source
{
    self.error = source.error;
    self.state = SGFFSessionStateFailed;
    if ([self.delegate respondsToSelector:@selector(sessionDidFailed:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate sessionDidFailed:self];
        });
    }
}

- (void)sourceDidFinished:(id<SGFFSource>)source
{
    self.state = SGFFSessionStateFinished;
    if ([self.delegate respondsToSelector:@selector(sessionDidFinished:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate sessionDidFinished:self];
        });
    }
}

#pragma mark - SGFFCodecDelegate

- (void)codecDidChangeCapacity:(id <SGFFCodec>)codec
{
    [self updateCapacity];
}

- (void)codec:(id <SGFFCodec>)codec hasNewFrame:(id <SGFFFrame>)frame
{
    if (codec == self.audioCodec)
    {
        [self.audioOutput putFrame:frame];
    }
    else if (codec == self.videoCodec)
    {
        [self.videoOutput putFrame:frame];
    }
}

#pragma mark - SGFFOutputDelegate

- (void)outputDidChangeCapacity:(id <SGFFOutput>)output
{
    if (output == self.audioOutput)
    {
        if (self.audioOutput.count >= 5) {
            [self.audioCodec pause];
        } else {
            [self.audioCodec resume];
        }
    }
    else if (output == self.videoOutput)
    {
        if (self.videoOutput.count >= 3) {
            [self.videoCodec pause];
        } else {
            [self.videoCodec resume];
        }
    }
    [self updateCapacity];
}

@end
