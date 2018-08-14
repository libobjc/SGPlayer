//
//  SGFormatContext.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/13.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFormatContext.h"
#import "SGError.h"

@interface SGFormatContext ()

@end

@implementation SGFormatContext

- (instancetype)initWithURL:(NSURL *)URL
{
    return [self initWithURL:URL offset:kCMTimeZero scale:CMTimeMake(1, 1)];
}

- (instancetype)initWithURL:(NSURL *)URL offset:(CMTime)offset scale:(CMTime)scale
{
    if (self = [super init])
    {
        _URL = URL;
        _offset = offset;
        _scale = scale;
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

- (BOOL)openWithOpaque:(void *)opaque callback:(int (*)(void *))callback
{
    NSError * error = nil;
    AVFormatContext * formatContext = NULL;
    BOOL success = SGCreateFormatContext(&formatContext, self.URL, opaque, callback, &error);
    if (!success)
    {
        _error = error;
        return NO;
    }
    if (formatContext->duration > 0)
    {
        _originalDuration = CMTimeMake(formatContext->duration, AV_TIME_BASE);
        _duration = SGTimeMultiplyByTime(self.originalDuration, self.scale);
    }
    if (CMTimeCompare(self.duration, kCMTimeZero) > 0 &&
        formatContext->pb)
    {
        _seekable = formatContext->pb->seekable;
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
                [audioStreams addObject:obj];
                break;
            case AVMEDIA_TYPE_VIDEO:
                [videoStreams addObject:obj];
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

BOOL SGCreateFormatContext(AVFormatContext ** formatContext, NSURL * URL, void * opaque, int (*callback)(void *), NSError ** error)
{
    AVFormatContext * fc = avformat_alloc_context();
    if (!fc)
    {
        * error = SGFFCreateErrorCode(SGErrorCodeFormatCreate);
        return NO;
    }
    fc->interrupt_callback.callback = callback;
    fc->interrupt_callback.opaque = opaque;
    NSString * URLString = URL.isFileURL ? URL.path : URL.absoluteString;
    int suc = avformat_open_input(&fc, URLString.UTF8String, NULL, NULL);
    NSError * err = SGFFGetErrorCode(suc, SGErrorCodeFormatOpenInput);
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
    err = SGFFGetErrorCode(suc, SGErrorCodeFormatFindStreamInfo);
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
