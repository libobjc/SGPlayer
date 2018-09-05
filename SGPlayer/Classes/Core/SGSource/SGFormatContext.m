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

@implementation SGFormatContext

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init])
    {
        _URL = URL;
        _scale = CMTimeMake(1, 1);
        _startTime = kCMTimeZero;
        _validTimeRange = CMTimeRangeMake(kCMTimeIndefinite, kCMTimeIndefinite);
        _duration = kCMTimeZero;
        _originalDuration = kCMTimeZero;
        _seekable = NO;
    }
    return self;
}

- (void)dealloc
{
    [self destory];
}

- (BOOL)openWithOptions:(NSDictionary *)options opaque:(void *)opaque callback:(int (*)(void *))callback
{
    NSError * error = nil;
    AVFormatContext * formatContext = NULL;
    BOOL success = SGCreateFormatContext(&formatContext, self.URL, options, opaque, callback, &error);
    if (!success)
    {
        _error = error;
        return NO;
    }
    if (formatContext->duration > 0)
    {
        _originalDuration = CMTimeMake(formatContext->duration, AV_TIME_BASE);
        _duration = SGCMTimeMultiply(self.originalDuration, self.scale);
    }
    if (CMTimeCompare(self.duration, kCMTimeZero) > 0 &&
        formatContext->pb)
    {
        _seekable = formatContext->pb->seekable;
    }
    if (formatContext->metadata)
    {
        _metadata = SGDictionaryFF2NS(formatContext->metadata);
    }
    NSMutableArray <SGStream *> * streams = [NSMutableArray array];
    NSMutableArray <SGStream *> * audioStreams = [NSMutableArray array];
    NSMutableArray <SGStream *> * videoStreams = [NSMutableArray array];
    NSMutableArray <SGStream *> * subtitleStreams = [NSMutableArray array];
    NSMutableArray <SGStream *> * otherStreams = [NSMutableArray array];
    for (int i = 0; i < formatContext->nb_streams; i++)
    {
        SGStream * obj = [[SGStream alloc] init];
        obj.coreStream = formatContext->streams[i];
        [streams addObject:obj];
        switch (obj.coreStream->codecpar->codec_type)
        {
            case AVMEDIA_TYPE_AUDIO:
                _audioEnable = YES;
                [audioStreams addObject:obj];
                break;
            case AVMEDIA_TYPE_VIDEO:
                if ((obj.coreStream->disposition & AV_DISPOSITION_ATTACHED_PIC) == 0)
                {
                    _videoEnable = YES;
                    [videoStreams addObject:obj];
                }
                else
                {
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
    _streams = [streams copy];
    _audioStreams = [audioStreams copy];
    _videoStreams = [videoStreams copy];
    _subtitleStreams = [subtitleStreams copy];
    _otherStreams = [otherStreams copy];
    _coreFormatContext = formatContext;
    return YES;
}

- (void)destory
{
    if (self.coreFormatContext)
    {
        avformat_close_input(&_coreFormatContext);
        _coreFormatContext = NULL;
    }
}

BOOL SGCreateFormatContext(AVFormatContext ** formatContext, NSURL * URL, NSDictionary * options, void * opaque, int (*callback)(void *), NSError ** error)
{
    AVFormatContext * fc = avformat_alloc_context();
    if (!fc)
    {
        * error = SGECreateError(@"", SGErrorCodeFormatCreate);
        return NO;
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
    
    NSError * err = SGEGetErrorCode(suc, SGErrorCodeFormatOpenInput);
    if (err)
    {
        if (fc)
        {
            avformat_free_context(fc);
        }
        * error = err;
        return NO;
    }
    
    suc = avformat_find_stream_info(fc, NULL);
    err = SGEGetErrorCode(suc, SGErrorCodeFormatFindStreamInfo);
    if (err)
    {
        if (fc)
        {
            avformat_close_input(&fc);
            avformat_free_context(fc);
        }
        * error = err;
        return NO;
    }
    * formatContext = fc;
    return YES;
}

@end
