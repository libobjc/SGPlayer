//
//  SGFormatContext.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/13.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFormatContext2.h"
#import "SGMapping.h"
#import "SGError.h"
#import "SGTrack+Internal.h"

@implementation SGFormatContext2

- (instancetype)initWithURL:(NSURL *)URL scale:(CMTime)scale startTime:(CMTime)startTime preferredTimeRange:(CMTimeRange)preferredTimeRange
{
    if (self = [super init])
    {
        _URL = URL;
        _scale = scale;
        _startTime = startTime;
        _actualTimeRange = CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity);
        _preferredTimeRange = preferredTimeRange;
        _duration = kCMTimeZero;
        _originalDuration = kCMTimeZero;
        _seekable = NO;
    }
    return self;
}

- (void)dealloc
{
    [self destroy];
}

- (BOOL)openWithOptions:(NSDictionary *)options opaque:(void *)opaque callback:(int (*)(void *))callback
{
    NSError * error = nil;
    AVFormatContext * formatContext = NULL;
    BOOL success = SGCreateFormatContext2(&formatContext, self.URL, options, opaque, callback, &error);
    if (!success)
    {
        _error = error;
        return NO;
    }
    if (formatContext->duration > 0)
    {
        _originalDuration = CMTimeMake(formatContext->duration, AV_TIME_BASE);
        _actualTimeRange = CMTimeRangeGetIntersection(self.preferredTimeRange, CMTimeRangeMake(kCMTimeZero, self.originalDuration));
        _duration = SGCMTimeMultiply(_actualTimeRange.duration, self.scale);
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
    NSMutableArray <SGTrack *> * tracks = [NSMutableArray array];
    NSMutableArray <SGTrack *> * audioTracks = [NSMutableArray array];
    NSMutableArray <SGTrack *> * videoTracks = [NSMutableArray array];
    NSMutableArray <SGTrack *> * subtitleTracks = [NSMutableArray array];
    NSMutableArray <SGTrack *> * otherTracks = [NSMutableArray array];
    for (int i = 0; i < formatContext->nb_tracks; i++)
    {
        SGTrack * obj = [[SGTrack alloc] initWithCore:_coreFormatContext->tracks[i]];
        [tracks addObject:obj];
        switch (obj.core->codecpar->codec_type)
        {
            case AVMEDIA_TYPE_AUDIO:
                _audioEnable = YES;
                [audioTracks addObject:obj];
                break;
            case AVMEDIA_TYPE_VIDEO:
                if ((obj.core->disposition & AV_DISPOSITION_ATTACHED_PIC) == 0)
                {
                    _videoEnable = YES;
                    [videoTracks addObject:obj];
                }
                else
                {
                    [otherTracks addObject:obj];
                }
                break;
            case AVMEDIA_TYPE_SUBTITLE:
                [subtitleTracks addObject:obj];
                break;
            default:
                [otherTracks addObject:obj];
                break;
        }
    }
    _tracks = [tracks copy];
    _audioTracks = [audioTracks copy];
    _videoTracks = [videoTracks copy];
    _subtitleTracks = [subtitleTracks copy];
    _otherTracks = [otherTracks copy];
    _coreFormatContext = formatContext;
    return YES;
}

- (void)destroy
{
    if (self.coreFormatContext)
    {
        avformat_close_input(&_coreFormatContext);
        _coreFormatContext = NULL;
    }
}

BOOL SGCreateFormatContext2(AVFormatContext ** formatContext, NSURL * URL, NSDictionary * options, void * opaque, int (*callback)(void *), NSError ** error)
{
    AVFormatContext * fc = avformat_alloc_context();
    if (!fc)
    {
        * error = SGECreateError(SGErrorCodeNoValidFormat, SGOperationCodeFormatCreate);
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
    
    NSError * err = SGEGetError(suc, SGOperationCodeFormatOpenInput);
    if (err)
    {
        if (fc)
        {
            avformat_free_context(fc);
        }
        * error = err;
        return NO;
    }
    
    suc = avformat_find_track_info(fc, NULL);
    err = SGEGetError(suc, SGOperationCodeFormatFindTrackInfo);
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
