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
#import "SGFFLog.h"

@interface SGFFSession () <SGFFSourceDelegate, SGFFCodecCapacityDelegate, SGFFCodecProcessingDelegate, SGFFOutputRenderSource>

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, weak) id <SGFFSessionDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) SGFFSessionConfiguration * configuration;

@property (nonatomic, assign) SGFFSessionState state;
@property (nonatomic, copy) NSError * error;

@property (nonatomic, strong) id <SGFFSource> source;

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
}

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^)(BOOL))completionHandler
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
        [strongSelf.configuration.videoOutput flush];
        if (completionHandler)
        {
            completionHandler(success);
        }
    }];
}


#pragma mark - Setter/Getter

- (NSTimeInterval)duration
{
    return self.source.duration;
}

- (NSTimeInterval)loadedDuration
{
    return self.source.loadedDuration;
}

- (long long)loadedSize
{
    return self.source.loadedSize;
}

- (BOOL)videoEnable
{
    return self.source.currentVideoStream != nil;
}

- (BOOL)audioEnable
{
    return self.source.currentAudioStream != nil;
}

- (BOOL)seekEnable
{
    return self.source.seekable;
}


#pragma mark - SGFFSourceDelegate

- (id <SGFFCodec>)source:(id <SGFFSource>)source codecForStream:(SGFFStream *)stream
{
    id <SGFFCodec> codec = nil;
    switch (stream.coreStream->codecpar->codec_type)
    {
        case AVMEDIA_TYPE_AUDIO:
        {
            SGFFAudioAVCodec * audioCodec = [[SGFFAudioAVCodec alloc] init];
            audioCodec.timebase = SGFFTimebaseValidate(stream.coreStream->time_base.num, stream.coreStream->time_base.den, 1, 44100);
            audioCodec.codecpar = stream.coreStream->codecpar;
            codec = audioCodec;
        }
            break;
        case AVMEDIA_TYPE_VIDEO:
        {
            Class codecClass = [SGFFVideoAVCodec class];
            if (self.configuration.enableVideoToolBox && stream.coreStream->codecpar->codec_id == AV_CODEC_ID_H264)
            {
                codecClass = [SGFFVideoVTBCodec class];
            }
            SGFFAsyncCodec * videoCodec = [[codecClass alloc] init];
            videoCodec.timebase = SGFFTimebaseValidate(stream.coreStream->time_base.num, stream.coreStream->time_base.den, 1, 25000);
            videoCodec.codecpar = stream.coreStream->codecpar;
            codec = videoCodec;
        }
            break;
        default:
            break;
    }
    codec.capacityDelegate = self;
    codec.processingDelegate = self;
    return codec;
}

- (void)sourceDidOpened:(id <SGFFSource>)source
{
    self.configuration.audioOutput.renderSource = self;
    self.configuration.videoOutput.renderSource = self;
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


#pragma mark - SGFFCodecCapacityDelegate

- (void)codecDidChangeCapacity:(id <SGFFCodec>)codec
{
    BOOL shouldPaused = NO;
    if (self.source.loadedSize > 15 * 1024 * 1024)
    {
        shouldPaused = YES;
    }
    else
    {
        id <SGFFCodec> mainCodec = nil;
        if (self.source.currentAudioStream)
        {
            mainCodec = self.source.currentAudioStream.codec;
        }
        else if (self.source.currentVideoStream)
        {
            mainCodec = self.source.currentVideoStream.codec;
        }
        if (mainCodec && SGFFTimestampConvertToSeconds(mainCodec.duration, mainCodec.timebase) > 10)
        {
            shouldPaused = YES;
        }
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


#pragma mark - SGFFCodecProcessingDelegate

- (id <SGFFFrame>)codec:(id <SGFFCodec>)codec processingFrame:(id <SGFFFrame>)frame
{
    NSArray <id <SGFFFilter>> * filters = nil;
    switch (frame.type)
    {
        case SGFFFrameTypeAudio:
            filters = self.configuration.audioFilters;
            break;
        case SGFFFrameTypeVideo:
            filters = self.configuration.videoFilters;
            break;
        default:
            break;
    }
    for (id <SGFFFilter> obj in filters)
    {
        frame = [obj processingFrame:frame];
    }
    return frame;
}

- (id <SGFFOutputRender>)codec:(id <SGFFCodec>)codec processingOutputRender:(id <SGFFFrame>)frame
{
    switch (frame.type)
    {
        case SGFFFrameTypeAudio:
            return [self.configuration.audioOutput renderWithFrame:frame];
        case SGFFFrameTypeVideo:
            return [self.configuration.videoOutput renderWithFrame:frame];
        default:
            return nil;
    }
}


#pragma mark - SGFFOutputRenderSource

- (id <SGFFOutputRender>)outputFecthRender:(id <SGFFOutput>)output
{
    switch (output.type)
    {
        case SGFFOutputTypeAudio:
            return [self.source.currentAudioStream.codec getOutputRender];
        case SGFFOutputTypeVideo:
            return [self.source.currentVideoStream.codec getOutputRender];
        default:
            return nil;
    }
}

- (id <SGFFOutputRender>)outputFecthRender:(id <SGFFOutput>)output positionHandler:(BOOL (^)(long long *, long long *))positionHandler
{
    switch (output.type)
    {
        case SGFFOutputTypeAudio:
            return [self.source.currentAudioStream.codec getOutputRenderWithPositionHandler:positionHandler];
        case SGFFOutputTypeVideo:
            return [self.source.currentVideoStream.codec getOutputRenderWithPositionHandler:positionHandler];
        default:
            return nil;
    }
}


@end
