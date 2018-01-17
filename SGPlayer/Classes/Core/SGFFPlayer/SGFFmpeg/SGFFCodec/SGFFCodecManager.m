//
//  SGFFCodecManager.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFCodecManager.h"
#import "SGFFVideoCodec.h"
#import "SGFFAudioCodec.h"
#import "SGFFUtil.h"

@interface SGFFCodecManager ()

@property (nonatomic, weak) id <SGFFCodecManagerDelegate> delegate;
@property (nonatomic, strong) NSArray <SGFFStream *> * streams;
@property (nonatomic, strong) NSArray <SGFFStream *> * videoStreams;
@property (nonatomic, strong) NSArray <SGFFStream *> * audioStreams;
@property (nonatomic, strong) NSArray <SGFFStream *> * subtitleStreams;
@property (nonatomic, strong) SGFFStream * currentVideoStream;
@property (nonatomic, strong) SGFFStream * currentAudioStream;
@property (nonatomic, strong) SGFFStream * currentSubtitleStream;

@property (nonatomic, copy) NSError * error;

@end

@implementation SGFFCodecManager

- (instancetype)initWithStreams:(NSArray <SGFFStream *> *)streams delegate:(id <SGFFCodecManagerDelegate>)delegate
{
    if (self = [super init])
    {
        self.streams = streams;
        self.delegate = delegate;
    }
    return self;
}

- (void)open
{
    NSMutableArray <SGFFStream *> * videoStreams = [NSMutableArray array];
    NSMutableArray <SGFFStream *> * audioStreams = [NSMutableArray array];
    NSMutableArray <SGFFStream *> * subtitleStreams = [NSMutableArray array];
    
    for (SGFFStream * obj in self.streams)
    {
        switch (obj.stream->codecpar->codec_type)
        {
            case AVMEDIA_TYPE_VIDEO:
                [videoStreams addObject:obj];
                break;
            case AVMEDIA_TYPE_AUDIO:
                [audioStreams addObject:obj];
                break;
            case AVMEDIA_TYPE_SUBTITLE:
                [subtitleStreams addObject:obj];
                break;
            default:
                break;
        }
    }
    
    SGFFStream * videoStream;
    SGFFStream * audioStream;
    SGFFStream * subtitleStream;
    [self selectStreams:videoStreams ref:&videoStream];
    [self selectStreams:audioStreams ref:&audioStream];
    [self selectStreams:subtitleStreams ref:&subtitleStream];
    
    self.videoStreams = videoStreams;
    self.audioStreams = audioStreams;
    self.subtitleStreams = subtitleStreams;
    self.currentVideoStream = videoStream;
    self.currentAudioStream = audioStream;
    self.currentSubtitleStream = subtitleStream;
    
    if (self.currentVideoStream || self.currentAudioStream)
    {
        if ([self.delegate respondsToSelector:@selector(codecManagerDidOpened:)]) {
            [self.delegate codecManagerDidOpened:self];
        }
    }
    else
    {
        self.error = SGFFCreateErrorCode(SGFFErrorCodeStreamNotFound);
        if ([self.delegate respondsToSelector:@selector(codecManagerDidFailed:)]) {
            [self.delegate codecManagerDidFailed:self];
        }
    }
}

- (BOOL)selectStreams:(NSArray <SGFFStream *> *)streams ref:(SGFFStream **)streamRef
{
    for (SGFFStream * obj in streams)
    {
        BOOL result = [self selectStream:obj ref:streamRef];
        if (result) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)selectStream:(SGFFStream *)stream ref:(SGFFStream **)streamRef
{
    BOOL result = [self openStream:stream];
    if (result)
    {
        [self closeStream:* streamRef];
        * streamRef = stream;
        return YES;
    }
    return NO;
}

- (BOOL)openStream:(SGFFStream *)stream
{
    switch (stream.stream->codecpar->codec_type)
    {
        case AVMEDIA_TYPE_VIDEO:
        {
            AVCodecContext * codecContext = [self codecContextWithStream:stream.stream];
            if (codecContext)
            {
                SGFFVideoCodec * videoCodec = [[SGFFVideoCodec alloc] init];
                videoCodec.codecContext = codecContext;
                stream.codec = videoCodec;
            }
        }
            break;
        case AVMEDIA_TYPE_AUDIO:
        {
            AVCodecContext * codecContext = [self codecContextWithStream:stream.stream];
            if (codecContext)
            {
                SGFFAudioCodec * audioCodec = [[SGFFAudioCodec alloc] init];
                audioCodec.codecContext = codecContext;
                stream.codec = audioCodec;
            }
        }
            break;
        default:
            break;
    }
    return stream.codec != nil;
}

- (AVCodecContext *)codecContextWithStream:(AVStream *)stream
{
    AVCodecContext * codecContext = avcodec_alloc_context3(NULL);
    if (!codecContext)
    {
        return nil;
    }
    
    int result = avcodec_parameters_to_context(codecContext, stream->codecpar);
    NSError * error = SGFFGetError(result);
    if (error)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    av_codec_set_pkt_timebase(codecContext, stream->time_base);
    
    AVCodec * codec = avcodec_find_decoder(codecContext->codec_id);
    if (!codec)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    codecContext->codec_id = codec->id;
    
    result = avcodec_open2(codecContext, codec, NULL);
    error = SGFFGetError(result);
    if (error)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    
    return codecContext;
}

- (void)closeStream:(SGFFStream *)stream
{
    [stream.codec close];
    stream.codec = nil;
}

@end
