//
//  SGFormatContext.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/13.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFormatContext.h"
#import "SGTrack+Internal.h"
#import "SGPacket+Internal.h"
#import "SGConfiguration.h"
#import "SGMapping.h"
#import "SGFFmpeg.h"
#import "SGError.h"

static int SGFormatContextInterruptHandler(void * context)
{
    SGFormatContext * obj = (__bridge SGFormatContext *)context;
    if ([obj.delegate respondsToSelector:@selector(formatContextShouldAbortBlockingFunctions:)]) {
        BOOL ret = [obj.delegate formatContextShouldAbortBlockingFunctions:obj];
        return ret ? 1 : 0;
    }
    return 0;
}

@interface SGFormatContext ()

{
    AVFormatContext * _formatContext;
}

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, copy) NSDictionary * metadata;
@property (nonatomic, copy) NSArray <SGTrack *> * tracks;
@property (nonatomic, copy) NSArray <SGTrack *> * videoTracks;
@property (nonatomic, copy) NSArray <SGTrack *> * audioTracks;
@property (nonatomic, copy) NSArray <SGTrack *> * otherTracks;

@end

@implementation SGFormatContext

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
    if (_formatContext && _formatContext->duration > 0) {
        return CMTimeMake(_formatContext->duration, AV_TIME_BASE);
    }
    return kCMTimeZero;
}

- (NSError *)open
{
    if (_formatContext) {
        return nil;
    }
    SGFFmpegSetupIfNeeded();
    NSError * error = SGCreateFormatContext(&_formatContext,
                                            self.URL,
                                            self.options,
                                            (__bridge void *)self,
                                            SGFormatContextInterruptHandler);
    if (error)
    {
        return error;
    }
    if (_formatContext && _formatContext->metadata) {
        self.metadata = SGDictionaryFF2NS(_formatContext->metadata);
    }
    NSMutableArray <SGTrack *> * tracks = [NSMutableArray array];
    NSMutableArray <SGTrack *> * audioTracks = [NSMutableArray array];
    NSMutableArray <SGTrack *> * videoTracks = [NSMutableArray array];
    NSMutableArray <SGTrack *> * otherTracks = [NSMutableArray array];
    for (int i = 0; i < _formatContext->nb_streams; i++) {
        SGTrack * obj = [[SGTrack alloc] initWithCore:_formatContext->streams[i]];
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
    if (_formatContext) {
        avformat_close_input(&_formatContext);
        _formatContext = NULL;
    }
    return nil;
}

- (NSError *)seekable
{
    if (_formatContext) {
        if (_formatContext->pb && _formatContext->pb->seekable > 0) {
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
    if (_formatContext) {
        int64_t timeStamp = AV_TIME_BASE * time.value / time.timescale;
        int ret = av_seek_frame(_formatContext, -1, timeStamp, AVSEEK_FLAG_BACKWARD);
        return SGEGetError(ret, SGOperationCodeFormatSeekFrame);
    }
    return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatSeekFrame);
}

- (NSError *)nextPacket:(SGPacket *)packet
{
    if (_formatContext) {
        int ret = av_read_frame(_formatContext, packet.core);
        return SGEGetError(ret, SGOperationCodeFormatReadFrame);
    }
    return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatReadFrame);
}

NSError * SGCreateFormatContext(AVFormatContext ** formatContext, NSURL * URL, NSDictionary * options, void * opaque, int (*callback)(void *))
{
    AVFormatContext * fc = avformat_alloc_context();
    if (!fc) {
        return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatCreate);
    }
    
    fc->interrupt_callback.callback = callback;
    fc->interrupt_callback.opaque = opaque;
    
    NSString * URLString = URL.isFileURL ? URL.path : URL.absoluteString;
    NSString * lowercaseURLString = [URLString lowercaseString];
    
    AVDictionary * opts = SGDictionaryNS2FF(options);
    if ([lowercaseURLString hasPrefix:@"rtmp"] ||
        [lowercaseURLString hasPrefix:@"rtsp"]) {
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
    * formatContext = fc;
    return nil;
}

@end
