//
//  SGFormatContext.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/13.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFormatContext.h"
#import "SGFFmpeg.h"
#import "SGError.h"

static int SGFormatContextInterruptHandler(void * context)
{
    SGFormatContext * obj = (__bridge SGFormatContext *)context;
    if ([obj.delegate respondsToSelector:@selector(formatContextShouldAbortBlockingFunctions:)])
    {
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
@property (nonatomic, copy) NSError * error;
@property (nonatomic, copy) NSDictionary * metadata;
@property (nonatomic, copy) NSArray <SGStream *> * streams;
@property (nonatomic, copy) NSArray <SGStream *> * videoStreams;
@property (nonatomic, copy) NSArray <SGStream *> * audioStreams;
@property (nonatomic, copy) NSArray <SGStream *> * otherStreams;

@end

@implementation SGFormatContext

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init])
    {
        self.URL = URL;
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

- (CMTime)duration
{
    if (_formatContext && _formatContext->duration > 0)
    {
        return CMTimeMake(_formatContext->duration, AV_TIME_BASE);
    }
    return kCMTimeZero;
}

- (NSError *)open
{
    if (_formatContext)
    {
        return nil;
    }
    NSError * error = SGCreateFormatContext(&_formatContext,
                                            self.URL,
                                            self.options,
                                            (__bridge void *)self,
                                            SGFormatContextInterruptHandler);
    if (error)
    {
        self.error = error;
        return error;
    }
    if (_formatContext && _formatContext->metadata)
    {
        self.metadata = SGDictionaryFF2NS(_formatContext->metadata);
    }
    NSMutableArray <SGStream *> * streams = [NSMutableArray array];
    NSMutableArray <SGStream *> * audioStreams = [NSMutableArray array];
    NSMutableArray <SGStream *> * videoStreams = [NSMutableArray array];
    NSMutableArray <SGStream *> * subtitleStreams = [NSMutableArray array];
    NSMutableArray <SGStream *> * otherStreams = [NSMutableArray array];
    for (int i = 0; i < _formatContext->nb_streams; i++)
    {
        SGStream * obj = [[SGStream alloc] init];
        obj.coreStream = _formatContext->streams[i];
        [streams addObject:obj];
        switch (obj.coreStream->codecpar->codec_type)
        {
            case AVMEDIA_TYPE_AUDIO:
                [audioStreams addObject:obj];
                break;
            case AVMEDIA_TYPE_VIDEO:
                if ((obj.coreStream->disposition & AV_DISPOSITION_ATTACHED_PIC) == 0) {
                    [videoStreams addObject:obj];
                } else {
                    [otherStreams addObject:obj];
                }
                break;
            case AVMEDIA_TYPE_SUBTITLE:
                [subtitleStreams addObject:obj];
                break;
            default:
                [otherStreams addObject:obj];
                break;
        }
    }
    self.streams = [streams copy];
    self.audioStreams = [audioStreams copy];
    self.videoStreams = [videoStreams copy];
    self.otherStreams = [otherStreams copy];
    return nil;
}

- (NSError *)close
{
    if (_formatContext)
    {
        avformat_close_input(&_formatContext);
        _formatContext = NULL;
    }
    return nil;
}

- (NSError *)seekable
{
    if (_formatContext)
    {
        if (_formatContext->pb && _formatContext->pb->seekable > 0)
        {
            return nil;
        }
        return SGECreateError(SGErrorCodeFormatNotSeekable, SGOperationCodeFormatGetSeekable);
    }
    return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatGetSeekable);
}

- (NSError *)seekToTime:(CMTime)time
{
    NSError * error = [self seekable];
    if (error)
    {
        return error;
    }
    if (_formatContext)
    {
        long long timeStamp = AV_TIME_BASE * time.value / time.timescale;
        int ret = av_seek_frame(_formatContext, -1, timeStamp, AVSEEK_FLAG_BACKWARD);
        return SGEGetError(ret, SGOperationCodeFormatSeekFrame);
    }
    return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatSeekFrame);
}

- (NSError *)nextPacket:(SGPacket *)packet
{
    if (_formatContext)
    {
        int ret = av_read_frame(_formatContext, packet.corePacket);
        return SGEGetError(ret, SGOperationCodeFormatReadFrame);
    }
    return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatReadFrame);
}

NSError * SGCreateFormatContext(AVFormatContext ** formatContext, NSURL * URL, NSDictionary * options, void * opaque, int (*callback)(void *))
{
    AVFormatContext * fc = avformat_alloc_context();
    if (!fc)
    {
        return SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatCreate);
    }
    
    fc->interrupt_callback.callback = callback;
    fc->interrupt_callback.opaque = opaque;
    
    NSString * URLString = URL.isFileURL ? URL.path : URL.absoluteString;
    NSString * lowercaseURLString = [URLString lowercaseString];
    
    AVDictionary * opts = SGDictionaryNS2FF(options);
    if ([lowercaseURLString hasPrefix:@"rtmp"] ||
        [lowercaseURLString hasPrefix:@"rtsp"])
    {
        av_dict_set(&opts, "timeout", NULL, 0);
    }
    
    int suc = avformat_open_input(&fc, URLString.UTF8String, NULL, &opts);
    
    if (opts)
    {
        av_dict_free(&opts);
    }
    
    NSError * err = SGEGetError(suc, SGOperationCodeFormatOpenInput);
    if (err)
    {
        if (fc)
        {
            avformat_free_context(fc);
        }
        return err;
    }
    
    suc = avformat_find_stream_info(fc, NULL);
    err = SGEGetError(suc, SGOperationCodeFormatFindStreamInfo);
    if (err)
    {
        if (fc)
        {
            avformat_close_input(&fc);
            avformat_free_context(fc);
        }
        return err;
    }
    * formatContext = fc;
    return nil;
}

@end
