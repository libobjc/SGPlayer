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
#import "SGMapping.h"
#import "SGFFmpeg.h"
#import "SGError.h"

static int SGURLDemuxerInterruptHandler(void * context)
{
    SGURLDemuxer * self = (__bridge SGURLDemuxer *)context;
    if ([self.delegate respondsToSelector:@selector(demuxableShouldAbortBlockingFunctions:)]) {
        BOOL ret = [self.delegate demuxableShouldAbortBlockingFunctions:self];
        return ret ? 1 : 0;
    }
    return 0;
}

@interface SGURLDemuxer ()

{
    AVFormatContext * _context;
}

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, copy) NSDictionary * metadata;
@property (nonatomic, copy) NSArray <SGTrack *> * tracks;
@property (nonatomic, copy) NSArray <SGTrack *> * audioTracks;
@property (nonatomic, copy) NSArray <SGTrack *> * videoTracks;
@property (nonatomic, copy) NSArray <SGTrack *> * otherTracks;

@end

@implementation SGURLDemuxer

@synthesize delegate = _delegate;
@synthesize options = _options;

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        self.URL = URL;
        self.options = [SGConfiguration defaultConfiguration].formatContextOptions;
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

- (CMTime)duration
{
    if (_context && _context->duration > 0) {
        return CMTimeMake(_context->duration, AV_TIME_BASE);
    }
    return kCMTimeZero;
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
    NSMutableArray <SGTrack *> * audioTracks = [NSMutableArray array];
    NSMutableArray <SGTrack *> * videoTracks = [NSMutableArray array];
    NSMutableArray <SGTrack *> * otherTracks = [NSMutableArray array];
    for (int i = 0; i < _context->nb_streams; i++) {
        SGTrack * obj = [[SGTrack alloc] initWithCore:_context->streams[i]];
        [tracks addObject:obj];
        switch (obj.type) {
            case SGMediaTypeAudio:
                [audioTracks addObject:obj];
                break;
            case SGMediaTypeVideo:
                if ((obj.disposition & AV_DISPOSITION_ATTACHED_PIC) == 0) {
                    [videoTracks addObject:obj];
                } else {
                    [otherTracks addObject:obj];
                }
                break;
            default:
                [otherTracks addObject:obj];
                break;
        }
    }
    self.tracks = [tracks copy];
    self.audioTracks = [audioTracks copy];
    self.videoTracks = [videoTracks copy];
    self.otherTracks = [otherTracks copy];
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

- (NSError *)seekToTime:(CMTime)time
{
    NSError * error = [self seekable];
    if (error) {
        return error;
    }
    if (_context) {
        int64_t timeStamp = AV_TIME_BASE * time.value / time.timescale;
        int ret = av_seek_frame(_context, -1, timeStamp, AVSEEK_FLAG_BACKWARD);
        return SGEGetError(ret, SGOperationCodeFormatSeekFrame);
    }
    return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatSeekFrame);
}

- (NSError *)nextPacket:(SGPacket *)packet
{
    if (_context) {
        int ret = av_read_frame(_context, packet.core);
        if (ret >= 0) {
            for (SGTrack * obj in self.tracks) {
                if (obj.index == packet.core->stream_index) {
                    [packet setTimebase:obj.core->time_base codecpar:obj.core->codecpar];
                    break;
                }
            }
        }
        return SGEGetError(ret, SGOperationCodeFormatReadFrame);
    }
    return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatReadFrame);
}

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

@end
