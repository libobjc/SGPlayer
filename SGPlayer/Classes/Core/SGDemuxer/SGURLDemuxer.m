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
#import "SGOptions.h"
#import "SGMapping.h"
#import "SGFFmpeg.h"
#import "SGError.h"

@interface SGURLDemuxer ()

@property (nonatomic, readonly) CMTime basetime;
@property (nonatomic, readonly) CMTime seektime;
@property (nonatomic, readonly) CMTime seektimeMinimum;
@property (nonatomic, readonly) AVFormatContext *context;

@end

@implementation SGURLDemuxer

@synthesize tracks = _tracks;
@synthesize options = _options;
@synthesize delegate = _delegate;
@synthesize metadata = _metadata;
@synthesize duration = _duration;
@synthesize finishedTracks = _finishedTracks;

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        self->_URL = [URL copy];
        self->_duration = kCMTimeInvalid;
        self->_basetime = kCMTimeInvalid;
        self->_seektime = kCMTimeInvalid;
        self->_seektimeMinimum = kCMTimeInvalid;
        self->_options = [SGOptions sharedOptions].demuxer.copy;
    }
    return self;
}

- (void)dealloc
{
    NSAssert(!self->_context, @"AVFormatContext is not released.");
}

#pragma mark - Control

- (id<SGDemuxable>)sharedDemuxer
{
    return self;
}

- (NSError *)open
{
    if (self->_context) {
        return nil;
    }
    SGFFmpegSetupIfNeeded();
    NSError *error = SGCreateFormatContext(&self->_context, self->_URL, self->_options.options, (__bridge void *)self, SGURLDemuxerInterruptHandler);
    if (error) {
        return error;
    }
    if (self->_context->duration > 0) {
        self->_duration = CMTimeMake(self->_context->duration, AV_TIME_BASE);
    }
    if (self->_context->metadata) {
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
        obj.core = stream;
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
        return SGCreateError(SGErrorCodeFormatNotSeekable, SGActionCodeFormatGetSeekable);
    }
    return SGCreateError(SGErrorCodeNoValidFormat, SGActionCodeFormatGetSeekable);
}

- (NSError *)seekToTime:(CMTime)time
{
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid];
}

- (NSError *)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter
{
    if (!CMTIME_IS_NUMERIC(time)) {
        return SGCreateError(SGErrorCodeInvlidTime, SGActionCodeFormatSeekFrame);
    }
    NSError *error = [self seekable];
    if (error) {
        return error;
    }
    if (self->_context) {
        int64_t timeStamp = CMTimeConvertScale(time, AV_TIME_BASE, kCMTimeRoundingMethod_RoundTowardZero).value;
        int ret = avformat_seek_file(self->_context, -1, INT64_MIN, timeStamp, INT64_MAX, AVSEEK_FLAG_BACKWARD);
        if (ret >= 0) {
            self->_seektime = time;
            self->_basetime = kCMTimeInvalid;
            if (CMTIME_IS_NUMERIC(toleranceBefor)) {
                self->_seektimeMinimum = CMTimeSubtract(time, CMTimeMaximum(toleranceBefor, kCMTimeZero));
            } else {
                self->_seektimeMinimum = kCMTimeInvalid;
            }
            self->_finishedTracks = nil;
        }
        return SGGetFFError(ret, SGActionCodeFormatSeekFrame);
    }
    return SGCreateError(SGErrorCodeNoValidFormat, SGActionCodeFormatSeekFrame);
}

- (NSError *)nextPacket:(SGPacket **)packet
{
    if (self->_context) {
        SGPacket *pkt = [SGPacket packet];
        int ret = av_read_frame(self->_context, pkt.core);
        if (ret < 0) {
            [pkt unlock];
        } else {
            AVStream *stream = self->_context->streams[pkt.core->stream_index];
            if (CMTIME_IS_INVALID(self->_basetime)) {
                self->_basetime = CMTimeMake(pkt.core->pts * stream->time_base.num, stream->time_base.den);
            }
            CMTime start = self->_basetime;
            if (CMTIME_IS_NUMERIC(self->_seektime)) {
                start = CMTimeMinimum(start, self->_seektime);
            }
            if (CMTIME_IS_NUMERIC(self->_seektimeMinimum)) {
                start = CMTimeMaximum(start, self->_seektimeMinimum);
            }
            SGCodecDescriptor *cd = [[SGCodecDescriptor alloc] init];
            cd.track = [self->_tracks objectAtIndex:pkt.core->stream_index];
            cd.metadata = SGDictionaryFF2NS(stream->metadata);
            cd.timebase = stream->time_base;
            cd.codecpar = stream->codecpar;
            [cd appendTimeRange:CMTimeRangeMake(start, kCMTimePositiveInfinity)];
            [pkt setCodecDescriptor:cd];
            [pkt fill];
            *packet = pkt;
        }
        NSError *error = SGGetFFError(ret, SGActionCodeFormatReadFrame);
        if (error.code == SGErrorCodeDemuxerEndOfFile) {
            self->_finishedTracks = self->_tracks.copy;
        }
        return error;
    }
    return SGCreateError(SGErrorCodeNoValidFormat, SGActionCodeFormatReadFrame);
}

#pragma mark - AVFormatContext

static NSError * SGCreateFormatContext(AVFormatContext **formatContext, NSURL *URL, NSDictionary *options, void *opaque, int (*callback)(void *))
{
    AVFormatContext *ctx = avformat_alloc_context();
    if (!ctx) {
        return SGCreateError(SGErrorCodeNoValidFormat, SGActionCodeFormatCreate);
    }
    ctx->interrupt_callback.callback = callback;
    ctx->interrupt_callback.opaque = opaque;
    NSString *URLString = URL.isFileURL ? URL.path : URL.absoluteString;
    AVDictionary *opts = SGDictionaryNS2FF(options);
    if ([URLString.lowercaseString hasPrefix:@"rtmp"] ||
        [URLString.lowercaseString hasPrefix:@"rtsp"]) {
        av_dict_set(&opts, "timeout", NULL, 0);
    }
    int success = avformat_open_input(&ctx, URLString.UTF8String, NULL, &opts);
    if (opts) {
        av_dict_free(&opts);
    }
    NSError *error = SGGetFFError(success, SGActionCodeFormatOpenInput);
    if (error) {
        if (ctx) {
            avformat_free_context(ctx);
        }
        return error;
    }
    success = avformat_find_stream_info(ctx, NULL);
    error = SGGetFFError(success, SGActionCodeFormatFindStreamInfo);
    if (error) {
        if (ctx) {
            avformat_close_input(&ctx);
            avformat_free_context(ctx);
        }
        return error;
    }
    *formatContext = ctx;
    return nil;
}

static int SGURLDemuxerInterruptHandler(void *demuxer)
{
    SGURLDemuxer *self = (__bridge SGURLDemuxer *)demuxer;
    if ([self->_delegate respondsToSelector:@selector(demuxableShouldAbortBlockingFunctions:)]) {
        BOOL ret = [self->_delegate demuxableShouldAbortBlockingFunctions:self];
        return ret ? 1 : 0;
    }
    return 0;
}

@end
