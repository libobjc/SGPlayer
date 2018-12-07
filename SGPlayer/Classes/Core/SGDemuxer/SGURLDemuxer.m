//
//  SGURLDemuxer.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/13.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGURLDemuxer.h"
#import "SGPacket+Internal.h"
#import "SGTrack+Internal.h"
#import "SGConfiguration.h"
#import "SGObjectPool.h"
#import "SGMapping.h"
#import "SGFFmpeg.h"
#import "SGError.h"

@interface SGURLDemuxer ()

{
    NSURL *_URL;
    CMTime _duration;
    CMTime _startTime;
    NSDictionary *_metadata;
    AVFormatContext *_context;
    NSArray<SGTrack *> *_tracks;
}

@end

@implementation SGURLDemuxer

@synthesize delegate = _delegate;
@synthesize options = _options;

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        self->_URL = URL;
        self->_options = [SGConfiguration sharedConfiguration].formatContextOptions;
        self->_startTime = kCMTimeNegativeInfinity;
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

#pragma mark - Setter & Getter

- (CMTime)duration
{
    return self->_duration;
}

- (NSDictionary *)metadata
{
    return [self->_metadata copy];
}

- (NSArray<SGTrack *> *)tracks
{
    return [self->_tracks copy];
}

#pragma mark - Control

- (NSError *)open
{
    if (self->_context) {
        return nil;
    }
    SGFFmpegSetupIfNeeded();
    NSError *error = SGCreateFormatContext(&self->_context, self->_URL, self->_options, (__bridge void *)self, SGURLDemuxerInterruptHandler);
    if (error) {
        return error;
    }
    if (self->_context && self->_context->duration > 0) {
        self->_duration = CMTimeMake(self->_context->duration, AV_TIME_BASE);
    } else {
        self->_duration = kCMTimeZero;
    }
    if (self->_context && self->_context->metadata) {
        self->_metadata = SGDictionaryFF2NS(self->_context->metadata);
    }
    NSMutableArray<SGTrack *> *tracks = [NSMutableArray array];
    for (int i = 0; i < self->_context->nb_streams; i++) {
        AVStream *stream = self->_context->streams[i];
        SGMediaType type = SGMediaTypeFF2SG(stream->codecpar->codec_type);
        if (type == SGMediaTypeVideo && stream->disposition & AV_DISPOSITION_ATTACHED_PIC) {
            type = SGMediaTypeUnknown;
        }
        SGTrack *obj = [[SGTrack alloc] initWithType:type index:i];
        [tracks addObject:obj];
    }
    self->_tracks = [tracks copy];
    return nil;
}

- (NSError *)close
{
    if (self->_context) {
        avformat_close_input(&self->_context);
        self->_context = NULL;
    }
    return nil;
}

- (NSError *)seekable
{
    if (self->_context) {
        if (self->_context->pb && self->_context->pb->seekable > 0) {
            return nil;
        }
        return SGECreateError(SGErrorCodeFormatNotSeekable, SGOperationCodeFormatGetSeekable);
    }
    return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatGetSeekable);
}

- (NSError *)seekToTime:(CMTime)time
{
    NSError *error = [self seekable];
    if (error) {
        return error;
    }
    if (self->_context) {
        int64_t timeStamp = CMTimeGetSeconds(CMTimeMultiply(time, AV_TIME_BASE));
        int ret = av_seek_frame(self->_context, -1, timeStamp, AVSEEK_FLAG_BACKWARD);
        if (ret >= 0) {
            self->_startTime = time;
        }
        return SGEGetError(ret, SGOperationCodeFormatSeekFrame);
    }
    return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatSeekFrame);
}

- (NSError *)nextPacket:(SGPacket **)packet
{
    if (self->_context) {
        SGPacket *pkt = [[SGObjectPool sharedPool] objectWithClass:[SGPacket class]];
        int ret = av_read_frame(self->_context, pkt.core);
        if (ret < 0) {
            [pkt unlock];
        } else {
            AVStream *stream = self->_context->streams[pkt.core->stream_index];
            SGCodecDescription *cd = [[SGCodecDescription alloc] init];
            cd.track = [self->_tracks objectAtIndex:pkt.core->stream_index];
            cd.timebase = stream->time_base;
            cd.codecpar = stream->codecpar;
            cd.timeRange = CMTimeRangeMake(self->_startTime, kCMTimePositiveInfinity);
            [pkt setCodecDescription:cd];
            [pkt fill];
            *packet = pkt;
        }
        return SGEGetError(ret, SGOperationCodeFormatReadFrame);
    }
    return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatReadFrame);
}

#pragma mark - AVFormatContext

static NSError * SGCreateFormatContext(AVFormatContext **format_context, NSURL *URL, NSDictionary *options, void *opaque, int (*callback)(void *))
{
    AVFormatContext *fmt_ctx = avformat_alloc_context();
    if (!fmt_ctx) {
        return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatCreate);
    }
    
    fmt_ctx->interrupt_callback.callback = callback;
    fmt_ctx->interrupt_callback.opaque = opaque;
    
    NSString *URLString = URL.isFileURL ? URL.path : URL.absoluteString;
    
    AVDictionary *opts = SGDictionaryNS2FF(options);
    if ([URLString.lowercaseString hasPrefix:@"rtmp"] ||
        [URLString.lowercaseString hasPrefix:@"rtsp"]) {
        av_dict_set(&opts, "timeout", NULL, 0);
    }
    
    int suc = avformat_open_input(&fmt_ctx, URLString.UTF8String, NULL, &opts);
    
    if (opts) {
        av_dict_free(&opts);
    }
    
    NSError *err = SGEGetError(suc, SGOperationCodeFormatOpenInput);
    if (err) {
        if (fmt_ctx) {
            avformat_free_context(fmt_ctx);
        }
        return err;
    }
    
    suc = avformat_find_stream_info(fmt_ctx, NULL);
    err = SGEGetError(suc, SGOperationCodeFormatFindStreamInfo);
    if (err) {
        if (fmt_ctx) {
            avformat_close_input(&fmt_ctx);
            avformat_free_context(fmt_ctx);
        }
        return err;
    }
    *format_context = fmt_ctx;
    return nil;
}

static int SGURLDemuxerInterruptHandler(void *context)
{
    SGURLDemuxer *self = (__bridge SGURLDemuxer *)context;
    if ([self->_delegate respondsToSelector:@selector(demuxableShouldAbortBlockingFunctions:)]) {
        BOOL ret = [self->_delegate demuxableShouldAbortBlockingFunctions:self];
        return ret ? 1 : 0;
    }
    return 0;
}

@end
