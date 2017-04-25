//
//  SGFFFormatContext.m
//  SGPlayer
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFFFormatContext.h"
#import "SGFFTools.h"

static int ffmpeg_interrupt_callback(void *ctx)
{
    SGFFFormatContext * obj = (__bridge SGFFFormatContext *)ctx;
    return [obj.delegate formatContextNeedInterrupt:obj];
}

@interface SGFFFormatContext ()

@property (nonatomic, copy) NSURL * contentURL;

@property (nonatomic, copy) NSError * error;
@property (nonatomic, copy) NSDictionary * metadata;

@property (nonatomic, assign) BOOL videoEnable;
@property (nonatomic, assign) BOOL audioEnable;

@property (nonatomic, strong) SGFFTrack * videoTrack;
@property (nonatomic, strong) SGFFTrack * audioTrack;

@property (nonatomic, strong) NSArray <SGFFTrack *> * videoTracks;
@property (nonatomic, strong) NSArray <SGFFTrack *> * audioTracks;

@property (nonatomic, assign) NSTimeInterval videoTimebase;
@property (nonatomic, assign) NSTimeInterval videoFPS;
@property (nonatomic, assign) CGSize videoPresentationSize;
@property (nonatomic, assign) CGFloat videoAspect;

@property (nonatomic, assign) NSTimeInterval audioTimebase;

@end

@implementation SGFFFormatContext

+ (instancetype)formatContextWithContentURL:(NSURL *)contentURL delegate:(id<SGFFFormatContextDelegate>)delegate
{
    return [[self alloc] initWithContentURL:contentURL delegate:delegate];
}

- (instancetype)initWithContentURL:(NSURL *)contentURL delegate:(id<SGFFFormatContextDelegate>)delegate
{
    if (self = [super init])
    {
        self.contentURL = contentURL;
        self.delegate = delegate;
    }
    return self;
}

- (void)setupSync
{
    self.error = [self openStream];
    if (self.error)
    {
        return;
    }
    
    [self openTracks];
    NSError * videoError = [self openVideoTrack];
    NSError * audioError = [self openAutioTrack];
    
    if (videoError && audioError)
    {
        if (videoError.code == SGFFDecoderErrorCodeStreamNotFound && audioError.code != SGFFDecoderErrorCodeStreamNotFound)
        {
            self.error = audioError;
        }
        else
        {
            self.error = videoError;
        }
        return;
    }
}

- (NSError *)openStream
{
    int reslut = 0;
    NSError * error = nil;
    
    self->_format_context = avformat_alloc_context();
    if (!_format_context)
    {
        reslut = -1;
        error = [NSError errorWithDomain:@"SGFFDecoderErrorCodeFormatCreate error" code:SGFFDecoderErrorCodeFormatCreate userInfo:nil];
        return error;
    }
    
    _format_context->interrupt_callback.callback = ffmpeg_interrupt_callback;
    _format_context->interrupt_callback.opaque = (__bridge void *)self;
    
    AVDictionary * options = SGFFFFmpegBrigeOfNSDictionary(self.formatContextOptions);
    
    // options filter.
    NSString * URLString = [self contentURLString];
    NSString * lowercaseURLString = [URLString lowercaseString];
    if ([lowercaseURLString hasPrefix:@"rtmp"] || [lowercaseURLString hasPrefix:@"rtsp"]) {
        av_dict_set(&options, "timeout", NULL, 0);
    }
    
    reslut = avformat_open_input(&_format_context, URLString.UTF8String, NULL, &options);
    if (options) {
        av_dict_free(&options);
    }
    error = SGFFCheckErrorCode(reslut, SGFFDecoderErrorCodeFormatOpenInput);
    if (error || !_format_context)
    {
        if (_format_context)
        {
            avformat_free_context(_format_context);
        }
        return error;
    }
    
    reslut = avformat_find_stream_info(_format_context, NULL);
    error = SGFFCheckErrorCode(reslut, SGFFDecoderErrorCodeFormatFindStreamInfo);
    if (error || !_format_context)
    {
        if (_format_context)
        {
            avformat_close_input(&_format_context);
        }
        return error;
    }
    self.metadata = SGFFFoundationBrigeOfAVDictionary(_format_context->metadata);
    
    return error;
}

- (void)openTracks
{
    NSMutableArray <SGFFTrack *> * videoTracks = [NSMutableArray array];
    NSMutableArray <SGFFTrack *> * audioTracks = [NSMutableArray array];
    
    for (int i = 0; i < _format_context->nb_streams; i++)
    {
        AVStream * stream = _format_context->streams[i];
        switch (stream->codecpar->codec_type)
        {
            case AVMEDIA_TYPE_VIDEO:
            {
                SGFFTrack * track = [[SGFFTrack alloc] init];
                track.type = SGFFTrackTypeVideo;
                track.index = i;
                track.metadata = [SGFFMetadata metadataWithAVDictionary:stream->metadata];
                [videoTracks addObject:track];
            }
                break;
            case AVMEDIA_TYPE_AUDIO:
            {
                SGFFTrack * track = [[SGFFTrack alloc] init];
                track.type = SGFFTrackTypeAudio;
                track.index = i;
                track.metadata = [SGFFMetadata metadataWithAVDictionary:stream->metadata];
                [audioTracks addObject:track];
            }
                break;
            default:
                break;
        }
    }
    
    if (videoTracks.count > 0)
    {
        self.videoTracks = videoTracks;
    }
    if (audioTracks.count > 0)
    {
        self.audioTracks = audioTracks;
    }
}

- (NSError *)openVideoTrack
{
    NSError * error = nil;
    
    if (self.videoTracks.count > 0)
    {
        for (SGFFTrack * obj in self.videoTracks)
        {
            int index = obj.index;
            if ((_format_context->streams[index]->disposition & AV_DISPOSITION_ATTACHED_PIC) == 0)
            {
                AVCodecContext * codec_context;
                error = [self openStreamWithTrackIndex:index codecContext:&codec_context domain:@"video"];
                if (!error)
                {
                    self.videoTrack = obj;
                    self.videoEnable = YES;
                    self.videoTimebase = SGFFStreamGetTimebase(_format_context->streams[index], 0.00004);
                    self.videoFPS = SGFFStreamGetFPS(_format_context->streams[index], self.videoTimebase);
                    self.videoPresentationSize = CGSizeMake(codec_context->width, codec_context->height);
                    self.videoAspect = (CGFloat)codec_context->width / (CGFloat)codec_context->height;
                    self->_video_codec_context = codec_context;
                    break;
                }
            }
        }
    }
    else
    {
        error = [NSError errorWithDomain:@"video stream not found" code:SGFFDecoderErrorCodeStreamNotFound userInfo:nil];
        return error;
    }
    
    return error;
}

- (NSError *)openAutioTrack
{
    NSError * error = nil;
    
    if (self.audioTracks.count > 0)
    {
        for (SGFFTrack * obj in self.audioTracks)
        {
            int index = obj.index;
            AVCodecContext * codec_context;
            error = [self openStreamWithTrackIndex:index codecContext:&codec_context domain:@"audio"];
            if (!error)
            {
                self.audioTrack = obj;
                self.audioEnable = YES;
                self.audioTimebase = SGFFStreamGetTimebase(_format_context->streams[index], 0.000025);
                self->_audio_codec_context = codec_context;
                break;
            }
        }
    }
    else
    {
        error = [NSError errorWithDomain:@"audio stream not found" code:SGFFDecoderErrorCodeStreamNotFound userInfo:nil];
        return error;
    }
    
    return error;
}

- (NSError *)openStreamWithTrackIndex:(int)trackIndex codecContext:(AVCodecContext **)codecContext domain:(NSString *)domain
{
    int result = 0;
    NSError * error = nil;
    
    AVStream * stream = _format_context->streams[trackIndex];
    AVCodecContext * codec_context = avcodec_alloc_context3(NULL);
    if (!codec_context)
    {
        error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@ codec context create error", domain]
                                    code:SGFFDecoderErrorCodeCodecContextCreate
                                userInfo:nil];
        return error;
    }
    
    result = avcodec_parameters_to_context(codec_context, stream->codecpar);
    error = SGFFCheckErrorCode(result, SGFFDecoderErrorCodeCodecContextSetParam);
    if (error)
    {
        avcodec_free_context(&codec_context);
        return error;
    }
    av_codec_set_pkt_timebase(codec_context, stream->time_base);
    
    AVCodec * codec = avcodec_find_decoder(codec_context->codec_id);
    if (!codec)
    {
        avcodec_free_context(&codec_context);
        error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@ codec not found decoder", domain]
                                    code:SGFFDecoderErrorCodeCodecFindDecoder
                                userInfo:nil];
        return error;
    }
    codec_context->codec_id = codec->id;
    
    AVDictionary * options = SGFFFFmpegBrigeOfNSDictionary(self.codecContextOptions);
    if (!av_dict_get(options, "threads", NULL, 0)) {
        av_dict_set(&options, "threads", "auto", 0);
    }
    if (codec_context->codec_type == AVMEDIA_TYPE_VIDEO || codec_context->codec_type == AVMEDIA_TYPE_AUDIO) {
        av_dict_set(&options, "refcounted_frames", "1", 0);
    }
    result = avcodec_open2(codec_context, codec, &options);
    error = SGFFCheckErrorCode(result, SGFFDecoderErrorCodeCodecOpen2);
    if (error)
    {
        avcodec_free_context(&codec_context);
        return error;
    }
    
    * codecContext = codec_context;
    return error;
}

- (void)seekFileWithFFTimebase:(NSTimeInterval)time
{
    int64_t ts = time * AV_TIME_BASE;
    av_seek_frame(self->_format_context, -1, ts, AVSEEK_FLAG_BACKWARD);
}

- (void)seekFileWithVideo:(NSTimeInterval)time
{
    if (self.videoEnable)
    {
        int64_t ts = time * 1000.0 / self.videoTimebase;
        av_seek_frame(self->_format_context, -1, ts, AVSEEK_FLAG_BACKWARD);
    }
    else
    {
        [self seekFileWithFFTimebase:time];
    }
}

- (void)seekFileWithAudio:(NSTimeInterval)time
{
    if (self.audioTimebase)
    {
        int64_t ts = time * 1000 / self.audioTimebase;
        av_seek_frame(self->_format_context, -1, ts, AVSEEK_FLAG_BACKWARD);
    }
    else
    {
        [self seekFileWithFFTimebase:time];
    }
}

- (int)readFrame:(AVPacket *)packet
{
    return av_read_frame(self->_format_context, packet);
}

- (BOOL)containAudioTrack:(int)audioTrackIndex
{
    for (SGFFTrack * obj in self.audioTracks) {
        if (obj.index == audioTrackIndex) {
            return YES;
        }
    }
    return NO;
}

- (NSError * )selectAudioTrackIndex:(int)audioTrackIndex
{
    if (audioTrackIndex == self.audioTrack.index) return nil;
    if (![self containAudioTrack:audioTrackIndex]) return nil;
    
    AVCodecContext * codec_context;
    NSError * error = [self openStreamWithTrackIndex:audioTrackIndex codecContext:&codec_context domain:@"audio select"];
    if (!error)
    {
        if (_audio_codec_context)
        {
            avcodec_close(_audio_codec_context);
            _audio_codec_context = NULL;
        }
        for (SGFFTrack * obj in self.audioTracks)
        {
            if (obj.index == audioTrackIndex)
            {
                self.audioTrack = obj;
            }
        }
        self.audioEnable = YES;
        self.audioTimebase = SGFFStreamGetTimebase(_format_context->streams[audioTrackIndex], 0.000025);
        self->_audio_codec_context = codec_context;
    }
    else
    {
        SGPlayerLog(@"select audio track error : %@", error);
    }
    return error;
}

- (NSTimeInterval)duration
{
    if (!self->_format_context) return 0;
    int64_t duration = self->_format_context->duration;
    if (duration < 0) {
        return 0;
    }
    return (NSTimeInterval)duration / AV_TIME_BASE;
}

- (BOOL)seekEnable
{
    if (!self->_format_context) return NO;
    BOOL ioSeekAble = YES;
    if (self->_format_context->pb) {
        ioSeekAble = self->_format_context->pb->seekable;
    }
    if (ioSeekAble && self.duration > 0) {
        return YES;
    }
    return NO;
}

- (NSTimeInterval)bitrate
{
    if (!self->_format_context) return 0;
    return (self->_format_context->bit_rate / 1000.0f);
}

- (NSString *)contentURLString
{
    if ([self.contentURL isFileURL])
    {
        return [self.contentURL path];
    }
    else
    {
        return [self.contentURL absoluteString];
    }
}

- (SGFFVideoFrameRotateType)videoFrameRotateType
{
    int rotate = [[self.videoTrack.metadata.metadata objectForKey:@"rotate"] intValue];
    if (rotate == 90) {
        return SGFFVideoFrameRotateType90;
    } else if (rotate == 180) {
        return SGFFVideoFrameRotateType180;
    } else if (rotate == 270) {
        return SGFFVideoFrameRotateType270;
    }
    return SGFFVideoFrameRotateType0;
}

- (void)destroyAudioTrack
{
    self.audioEnable = NO;
    self.audioTrack = nil;
    self.audioTracks = nil;
    
    if (_audio_codec_context)
    {
        avcodec_close(_audio_codec_context);
        _audio_codec_context = NULL;
    }
}

- (void)destroyVideoTrack
{
    self.videoEnable = NO;
    self.videoTrack = nil;
    self.videoTracks = nil;
    
    if (_video_codec_context)
    {
        avcodec_close(_video_codec_context);
        _video_codec_context = NULL;
    }
}

- (void)destroy
{
    [self destroyVideoTrack];
    [self destroyAudioTrack];
    if (_format_context)
    {
        avformat_close_input(&_format_context);
        _format_context = NULL;
    }
}

- (void)dealloc
{
    [self destroy];
    SGPlayerLog(@"SGFFFormatContext release");
}

@end
