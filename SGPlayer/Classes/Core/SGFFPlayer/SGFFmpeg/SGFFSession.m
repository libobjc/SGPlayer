//
//  SGFFSession.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFSession.h"
#import "SGFFFormatContext.h"
#import "SGFFStreamManager.h"
#import "SGFFAudioAVCodec.h"
#import "SGFFVideoAVCodec.h"
#import "SGFFVideoVTBCodec.h"
#import "SGPlayerMacro.h"
#import "SGFFLog.h"

@interface SGFFSession () <SGFFSourceDelegate, SGFFStreamManagerDelegate, SGFFCodecCapacityDelegate, SGFFCodecProcessingDelegate>

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, weak) id <SGFFSessionDelegate> delegate;
@property (nonatomic, strong) SGFFSessionConfiguration * configuration;
@property (nonatomic, copy) NSError * error;

@property (nonatomic, strong) id <SGFFSource> source;
@property (nonatomic, strong) SGFFStreamManager * streamManager;

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
    self.source = [[SGFFFormatContext alloc] initWithContentURL:self.contentURL delegate:self];
    [self.source open];
}

- (void)close
{
    [self.source close];
    [self.streamManager close];
}

- (void)seekToTime:(NSTimeInterval)timestamp
{
    [self.source seekToTime:timestamp];
}


#pragma mark - Callback

- (void)callbackForError
{
    if ([self.delegate respondsToSelector:@selector(session:didFailed:)]) {
        [self.delegate session:self didFailed:self.error];
    }
}


#pragma mark - SGFFSourceDelegate

- (void)sourceDidOpened:(id <SGFFSource>)source
{
    self.streamManager = [[SGFFStreamManager alloc] initWithStreams:self.source.streams delegate:self];
    [self.streamManager open];
}

- (void)sourceDidFailed:(id <SGFFSource>)source
{
    self.error = source.error;
    [self callbackForError];
}

- (void)sourceDidFinishedSeeking:(id <SGFFSource>)source
{
    [self.streamManager flush];
}

- (void)source:(id <SGFFSource>)source didOutputPacket:(SGFFPacket *)packet
{
    [self.streamManager putPacket:packet];
}


#pragma mark - SGFFStreamManagerDelegate

- (id <SGFFCodec>)streamManager:(SGFFStreamManager *)streamManager codecForStream:(SGFFStream *)stream
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
                if (self.configuration.enableVideoToolBox && stream.coreStream->codecpar->codec_id == AV_CODEC_ID_H264)
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

- (void)streamManagerDidOpened:(SGFFStreamManager *)streamManager
{
    self.configuration.audioOutput.renderSource = self.streamManager.currentAudioStream.codec;
    self.configuration.videoOutput.renderSource = self.streamManager.currentVideoStream.codec;
    [self.source read];
}

- (void)streamManagerDidFailed:(SGFFStreamManager *)streamManager
{
    self.error = streamManager.error;
    [self callbackForError];
}


#pragma marl - SGFFCodecCapacityDelegate

- (void)codecDidChangeCapacity:(id <SGFFCodec>)codec
{
    BOOL shouldPaused = NO;
    if (self.streamManager.size > 15 * 1024 * 1024)
    {
        shouldPaused = YES;
    }
    else if (codec == self.streamManager.currentAudioStream.codec)
    {
        if (SGFFTimestampConvertToSeconds(codec.duration, codec.timebase) > 10)
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


@end
