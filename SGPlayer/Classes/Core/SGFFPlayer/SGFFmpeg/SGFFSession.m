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

@interface SGFFSession () <SGFFSourceDelegate, SGFFCodecCapacityDelegate, SGFFCodecProcessingDelegate>

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, weak) id <SGFFSessionDelegate> delegate;
@property (nonatomic, strong) SGFFSessionConfiguration * configuration;
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
        self.configuration = configuration;
    }
    return self;
}

- (void)open
{
    if (self.configuration.customSource)
    {
        self.source = self.configuration.customSource;
    }
    else
    {
        self.source = [[SGFFFormatContext alloc] initWithContentURL:self.contentURL delegate:self];
    }
    [self.source open];
}

- (void)close
{
    [self.source close];
}

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^)(BOOL))completionHandler
{
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


#pragma mark - Callback

- (void)callbackForError
{
    if ([self.delegate respondsToSelector:@selector(session:didFailed:)])
    {
        [self.delegate session:self didFailed:self.error];
    }
}


#pragma mark - SGFFSourceDelegate

- (id <SGFFCodec>)source:(id <SGFFSource>)source codecForStream:(SGFFStream *)stream
{
    id <SGFFCodec> codec = nil;
    switch (stream.coreStream->codecpar->codec_type)
    {
        case AVMEDIA_TYPE_AUDIO:
        {
            if (self.configuration.customAudioCodec)
            {
                codec = self.configuration.customAudioCodec;
            }
            else
            {
                SGFFAudioAVCodec * audioCodec = [[SGFFAudioAVCodec alloc] init];
                audioCodec.timebase = SGFFTimebaseValidate(stream.coreStream->time_base.num, stream.coreStream->time_base.den, 1, 44100);
                audioCodec.codecpar = stream.coreStream->codecpar;
                codec = audioCodec;
            }
        }
            break;
        case AVMEDIA_TYPE_VIDEO:
        {
            if (self.configuration.customVideoCodec)
            {
                codec = self.configuration.customVideoCodec;
            }
            else
            {
                Class codecClass = [SGFFVideoAVCodec class];
                if (self.configuration.videoCodecVideoToolBoxEnable && stream.coreStream->codecpar->codec_id == AV_CODEC_ID_H264)
                {
                    codecClass = [SGFFVideoVTBCodec class];
                }
                SGFFAsyncCodec * videoCodec = [[codecClass alloc] init];
                videoCodec.timebase = SGFFTimebaseValidate(stream.coreStream->time_base.num, stream.coreStream->time_base.den, 1, 25000);
                videoCodec.codecpar = stream.coreStream->codecpar;
                codec = videoCodec;
            }
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
    self.configuration.audioOutput.renderSource = self.source.currentAudioStream.codec;
    self.configuration.videoOutput.renderSource = self.source.currentVideoStream.codec;
    [self.source read];
}

- (void)sourceDidFailed:(id <SGFFSource>)source
{
    self.error = source.error;
    [self callbackForError];
}


#pragma marl - SGFFCodecCapacityDelegate

- (void)codecDidChangeCapacity:(id <SGFFCodec>)codec
{
    BOOL shouldPaused = NO;
    if (self.source.size > 15 * 1024 * 1024)
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
}


#pragma mark - SGFFCodecProcessingDelegate

- (id <SGFFFrame>)codec:(id <SGFFCodec>)codec processingFrame:(id <SGFFFrame>)frame
{
    NSArray <id <SGFFFilter>> * filters = nil;
    switch (frame.type)
    {
        case SGFFFrameTypeAudio:
            filters = self.configuration.customAudioFilters;
            break;
        case SGFFFrameTypeVideo:
            filters = self.configuration.customVideoFilters;
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


@end
