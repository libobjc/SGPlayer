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

- (BOOL)open
{
    if (_formatContext)
    {
        return YES;
    }
    _error = SGCreateFormatContext(&_formatContext,
                                   self.URL,
                                   self.options,
                                   (__bridge void *)self,
                                   SGFormatContextInterruptHandler);
    if (self.error)
    {
        return NO;
    }
    return YES;
}

- (BOOL)close
{
    if (_formatContext)
    {
        avformat_close_input(&_formatContext);
        _formatContext = NULL;
    }
    return YES;
}

- (BOOL)seekable
{
    return YES;
}

- (BOOL)seekableToTime:(CMTime)time
{
    return self.seekable;
}

- (NSError *)seekToTime:(CMTime)time
{
    long long timeStamp = AV_TIME_BASE * time.value / time.timescale;
    int ret = av_seek_frame(_formatContext, -1, timeStamp, AVSEEK_FLAG_BACKWARD);
    return SGEGetError(ret);
}

- (NSError *)nextPacket:(SGPacket *)packet
{
    int ret = av_read_frame(_formatContext, packet.corePacket);
    return SGEGetError(ret);
}

NSError * SGCreateFormatContext(AVFormatContext ** formatContext, NSURL * URL, NSDictionary * options, void * opaque, int (*callback)(void *))
{
    AVFormatContext * fc = avformat_alloc_context();
    if (!fc)
    {
        return SGECreateError(@"", SGErrorCodeFormatCreate);
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
        return err;
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
        return err;
    }
    * formatContext = fc;
    return nil;
}

@end
