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

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, weak) id <SGFFSessionDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) SGFFSessionConfiguration * configuration;

@property (nonatomic, assign) SGFFSessionState state;
@property (nonatomic, copy) NSError * error;

@property (nonatomic, strong) id <SGFFSource> source;
@property (nonatomic, strong) id <SGFFDecoder> audioDecoder;
@property (nonatomic, strong) id <SGFFDecoder> videoDecoder;
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
    self.source = [[SGFFFormatContext alloc] init];
    self.source.URL = self.contentURL;
    self.source.delegate = self;
    [self.source openStreams];
}

- (void)read
{
    self.state = SGFFSessionStateReading;
    [self.source startReading];
}

- (void)close
{
    self.state = SGFFSessionStateClosed;
    [self.source stopReading];
    [self.audioDecoder stopDecoding];
    [self.videoDecoder stopDecoding];
    [self.audioOutput stop];
    [self.videoOutput stop];
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
        [self.audioDecoder flush];
        [self.videoDecoder flush];
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
    if (self.audioDecoder && self.audioOutput)
    {
        return CMTimeAdd(self.audioDecoder.duration, self.audioOutput.duration);
    }
    else if (self.videoDecoder && self.videoOutput)
    {
        return CMTimeAdd(self.videoDecoder.duration, self.videoOutput.duration);
    }
    return kCMTimeZero;
}

- (long long)loadedSize
{
    return self.audioDecoder.size + self.audioOutput.size + self.videoDecoder.size + self.videoOutput.size;
}

- (BOOL)videoEnable
{
    return self.videoDecoder != nil;
}

- (BOOL)audioEnable
{
    return self.audioDecoder != nil;
}

- (BOOL)seekEnable
{
    return self.source.seekable;
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
        if (self.audioOutput.count >= 5) {
            [self.audioDecoder pauseDecoding];
        } else {
            [self.audioDecoder resumeDecoding];
        }
    }
    else if (output == self.videoOutput)
    {
        if (self.videoOutput.count >= 3) {
            [self.videoDecoder pauseDecoding];
        } else {
            [self.videoDecoder resumeDecoding];
        }
    }
    [self updateCapacity];
}

@end
