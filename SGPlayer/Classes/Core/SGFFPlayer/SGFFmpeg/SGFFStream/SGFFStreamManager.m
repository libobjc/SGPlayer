//
//  SGFFStreamManager.m
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFStreamManager.h"
#import "SGFFUtil.h"

@interface SGFFStreamManager ()

@property (nonatomic, weak) id <SGFFStreamManagerDelegate> delegate;
@property (nonatomic, strong) NSArray <SGFFStream *> * streams;
@property (nonatomic, strong) NSArray <SGFFStream *> * videoStreams;
@property (nonatomic, strong) NSArray <SGFFStream *> * audioStreams;
@property (nonatomic, strong) NSArray <SGFFStream *> * subtitleStreams;
@property (nonatomic, strong) SGFFStream * currentVideoStream;
@property (nonatomic, strong) SGFFStream * currentAudioStream;
@property (nonatomic, strong) SGFFStream * currentSubtitleStream;

@property (nonatomic, copy) NSError * error;

@end

@implementation SGFFStreamManager

- (instancetype)initWithStreams:(NSArray <SGFFStream *> *)streams delegate:(id <SGFFStreamManagerDelegate>)delegate
{
    if (self = [super init])
    {
        self.streams = streams;
        self.delegate = delegate;
    }
    return self;
}

- (void)open
{
    NSMutableArray <SGFFStream *> * videoStreams = [NSMutableArray array];
    NSMutableArray <SGFFStream *> * audioStreams = [NSMutableArray array];
    NSMutableArray <SGFFStream *> * subtitleStreams = [NSMutableArray array];
    for (SGFFStream * obj in self.streams)
    {
        switch (obj.stream->codecpar->codec_type)
        {
            case AVMEDIA_TYPE_VIDEO:
                [videoStreams addObject:obj];
                break;
            case AVMEDIA_TYPE_AUDIO:
                [audioStreams addObject:obj];
                break;
            case AVMEDIA_TYPE_SUBTITLE:
                [subtitleStreams addObject:obj];
                break;
            default:
                break;
        }
    }
    self.videoStreams = videoStreams;
    self.audioStreams = audioStreams;
    self.subtitleStreams = subtitleStreams;
    
    [self selectStreams:self.videoStreams ref:&_currentVideoStream];
    [self selectStreams:self.audioStreams ref:&_currentAudioStream];
    [self selectStreams:self.subtitleStreams ref:&_currentSubtitleStream];
    
    if (self.currentVideoStream || self.currentAudioStream)
    {
        if ([self.delegate respondsToSelector:@selector(streamManagerDidOpened:)]) {
            [self.delegate streamManagerDidOpened:self];
        }
    }
    else
    {
        self.error = SGFFCreateErrorCode(SGFFErrorCodeStreamNotFound);
        if ([self.delegate respondsToSelector:@selector(streamManagerDidFailed:)]) {
            [self.delegate streamManagerDidFailed:self];
        }
    }
}

- (BOOL)selectStream:(SGFFStream *)stream
{
    switch (stream.stream->codecpar->codec_type)
    {
        case AVMEDIA_TYPE_VIDEO:
            return [self selectStream:stream ref:&_currentAudioStream];
        case AVMEDIA_TYPE_AUDIO:
            return [self selectStream:stream ref:&_currentAudioStream];
        case AVMEDIA_TYPE_SUBTITLE:
            return [self selectStream:stream ref:&_currentSubtitleStream];
        default:
            return NO;
    }
    return NO;
}

- (BOOL)selectStreams:(NSArray <SGFFStream *> *)streams ref:(SGFFStream * __strong *)streamRef
{
    for (SGFFStream * obj in streams)
    {
        BOOL result = [self selectStream:obj ref:streamRef];
        if (result) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)selectStream:(SGFFStream *)stream ref:(SGFFStream * __strong *)streamRef
{
    if ([self.delegate respondsToSelector:@selector(streamManager:codecForStream:)])
    {
        id <SGFFCodec> codec = [self.delegate streamManager:self codecForStream:stream];
        if (codec)
        {
            [self closeStream:* streamRef];
            stream.codec = codec;
            * streamRef = stream;
            return YES;
        }
    }
    return NO;
}

- (void)closeStream:(SGFFStream *)stream
{
    [stream.codec close];
    stream.codec = nil;
}

@end
