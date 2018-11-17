//
//  SGURLDemuxer.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/13.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGURLDemuxer.h"
#import "SGTrack+Internal.h"
#import "SGPacket+Internal.h"
#import "SGConfiguration.h"
#import "SGAudioDecoder.h"
#import "SGVideoDecoder.h"
#import "SGAudioFrame.h"
#import "SGVideoFrame.h"
#import "SGMapping.h"
#import "SGFFmpeg.h"
#import "avformat.h"
#import "SGError.h"

@interface SGURLDemuxer ()

{
    CMTime _start_time;
    AVFormatContext * _context;
}

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, copy) NSDictionary * metadata;
@property (nonatomic, copy) NSArray <SGTrack *> * tracks;

@end

@implementation SGURLDemuxer

@synthesize delegate = _delegate;
@synthesize options = _options;

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        self.URL = URL;
        self.options = [SGConfiguration defaultConfiguration].formatContextOptions;
        _start_time = kCMTimeNegativeInfinity;
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
    if (_context && _context->duration > 0) {
        return CMTimeMake(_context->duration, AV_TIME_BASE);
    }
    return kCMTimeZero;
}

#pragma mark - Interface

- (NSError *)open
{
    if (_context) {
        return nil;
    }
    SGFFmpegSetupIfNeeded();
    NSError * error = SGCreateFormatContext(&_context, self.URL, self.options, (__bridge void *)self, SGURLDemuxerInterruptHandler);
    if (error) {
        return error;
    }
    if (_context && _context->metadata) {
        self.metadata = SGDictionaryFF2NS(_context->metadata);
    }
    NSMutableArray <SGTrack *> * tracks = [NSMutableArray array];
    for (int i = 0; i < _context->nb_streams; i++) {
        AVStream * stream = _context->streams[i];
        SGMediaType type = SGMediaTypeFF2SG(stream->codecpar->codec_type);
        if (type == SGMediaTypeVideo && stream->disposition & AV_DISPOSITION_ATTACHED_PIC) {
            type = SGMediaTypeUnknown;
        }
        SGTrack * obj = [[SGTrack alloc] initWithType:type index:i];
        [tracks addObject:obj];
    }
    self.tracks = [tracks copy];
    return nil;
}

- (NSError *)close
{
    if (_context) {
        avformat_close_input(&_context);
        _context = NULL;
    }
    return nil;
}

- (NSError *)seekable
{
    if (_context) {
        if (_context->pb && _context->pb->seekable > 0) {
            return nil;
        }
        return SGECreateError(SGErrorCodeFormatNotSeekable, SGOperationCodeFormatGetSeekable);
    }
    return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatGetSeekable);
}

- (NSError *)seekToTime:(CMTime)time
{
    NSError * error = [self seekable];
    if (error) {
        return error;
    }
    if (_context) {
        int64_t timeStamp = AV_TIME_BASE * time.value / time.timescale;
        int ret = av_seek_frame(_context, -1, timeStamp, AVSEEK_FLAG_BACKWARD);
        if (ret >= 0) {
            _start_time = time;
        }
        return SGEGetError(ret, SGOperationCodeFormatSeekFrame);
    }
    return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatSeekFrame);
}

- (NSError *)nextPacket:(SGPacket **)packet
{
    if (_context) {
        SGPacket * pkt = [[SGObjectPool sharePool] objectWithClass:[SGPacket class]];
        int ret = av_read_frame(_context, pkt.core);
        if (ret < 0) {
            [pkt unlock];
        } else {
            AVStream * stream = _context->streams[pkt.core->stream_index];
            SGCodecDescription * cd = [[SGCodecDescription alloc] init];
            cd.index = pkt.core->stream_index;
            cd.timebase = stream->time_base;
            cd.codecpar = stream->codecpar;
            if (stream->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
                cd.frameClass = [SGAudioFrame class];
                cd.decoderClass = [SGAudioDecoder class];
            } else if (stream->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
                cd.frameClass = [SGVideoFrame class];
                cd.decoderClass = [SGVideoDecoder class];
            }
            cd.timeRange = CMTimeRangeMake(_start_time, kCMTimePositiveInfinity);
            pkt.codecDescription = cd;
            [pkt fill];
            *packet = pkt;
        }
        return SGEGetError(ret, SGOperationCodeFormatReadFrame);
    }
    return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatReadFrame);
}

#pragma mark - AVFormatContext

NSError * SGCreateFormatContext(AVFormatContext ** format_context, NSURL * URL, NSDictionary * options, void * opaque, int (*callback)(void *))
{
    AVFormatContext * fc = avformat_alloc_context();
    if (!fc) {
        return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatCreate);
    }
    
    fc->interrupt_callback.callback = callback;
    fc->interrupt_callback.opaque = opaque;
    
    NSString * URLString = URL.isFileURL ? URL.path : URL.absoluteString;
    
    AVDictionary * opts = SGDictionaryNS2FF(options);
    if ([URLString.lowercaseString hasPrefix:@"rtmp"] ||
        [URLString.lowercaseString hasPrefix:@"rtsp"]) {
        av_dict_set(&opts, "timeout", NULL, 0);
    }
    
    int suc = avformat_open_input(&fc, URLString.UTF8String, NULL, &opts);
    
    if (opts) {
        av_dict_free(&opts);
    }
    
    NSError * err = SGEGetError(suc, SGOperationCodeFormatOpenInput);
    if (err) {
        if (fc) {
            avformat_free_context(fc);
        }
        return err;
    }
    
    suc = avformat_find_stream_info(fc, NULL);
    err = SGEGetError(suc, SGOperationCodeFormatFindStreamInfo);
    if (err) {
        if (fc) {
            avformat_close_input(&fc);
            avformat_free_context(fc);
        }
        return err;
    }
    * format_context = fc;
    return nil;
}

static int SGURLDemuxerInterruptHandler(void * context)
{
    SGURLDemuxer * self = (__bridge SGURLDemuxer *)context;
    if ([self.delegate respondsToSelector:@selector(demuxableShouldAbortBlockingFunctions:)]) {
        BOOL ret = [self.delegate demuxableShouldAbortBlockingFunctions:self];
        return ret ? 1 : 0;
    }
    return 0;
}

@end
