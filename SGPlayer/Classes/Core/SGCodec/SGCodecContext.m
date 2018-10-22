//
//  SGCodecContext.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGCodecContext.h"
#import "SGObjectPool.h"
#import "SGFFmpeg.h"
#import "SGError.h"
#import "SGMacro.h"
#import "SGFFFrame.h"

@interface SGCodecContext ()

@property (nonatomic, assign) AVCodecContext * codecContext;
@property (nonatomic, assign) SGStream * stream;
@property (nonatomic, strong) Class frameClass;

@end

@implementation SGCodecContext

- (AVCodecContext *)createCcodecContext
{
    AVCodecContext * codecContext = avcodec_alloc_context3(NULL);
    if (!codecContext)
    {
        return nil;
    }
    
    int result = avcodec_parameters_to_context(codecContext, self.stream.coreStream->codecpar);
    NSError * error = SGEGetError(result, SGOperationCodeCodecSetParametersToContext);
    if (error)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    codecContext->pkt_timebase = self.stream.coreStream->time_base;
    
    AVCodec * codec = avcodec_find_decoder(codecContext->codec_id);
    if (!codec)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    codecContext->codec_id = codec->id;
    
    AVDictionary * opts = SGDictionaryNS2FF(self.options);
    if (self.threadsAuto &&
        !av_dict_get(opts, "threads", NULL, 0))
    {
        av_dict_set(&opts, "threads", "auto", 0);
    }
    if (self.refcountedFrames &&
        !av_dict_get(opts, "refcounted_frames", NULL, 0) &&
        (codecContext->codec_type == AVMEDIA_TYPE_VIDEO || codecContext->codec_type == AVMEDIA_TYPE_AUDIO))
    {
        av_dict_set(&opts, "refcounted_frames", "1", 0);
    }
    
    result = avcodec_open2(codecContext, codec, &opts);
    
    if (opts)
    {
        av_dict_free(&opts);
    }
    
    error = SGEGetError(result, SGOperationCodeCodecOpen2);
    if (error)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    
    return codecContext;
}

- (instancetype)initWithStream:(SGStream *)stream frameClass:(Class)frameClass
{
    if (self = [super init])
    {
        self.stream = stream;
        self.frameClass = frameClass;
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

- (BOOL)open
{
    if (!self.stream)
    {
        return NO;
    }
    if (!self.frameClass)
    {
        return NO;
    }
    self.codecContext = [self createCcodecContext];
    if (!self.codecContext)
    {
        return NO;
    }
    return YES;
}

- (void)flush
{
    if (self.codecContext)
    {
        avcodec_flush_buffers(self.codecContext);
    }
}

- (void)close
{
    if (self.codecContext)
    {
        avcodec_close(self.codecContext);
        self.codecContext = nil;
    }
}

- (NSArray <SGFrame *> *)decode:(SGPacket *)packet
{
    int result = avcodec_send_packet(self.codecContext, packet.corePacket);
    if (result < 0)
    {
        return nil;
    }
    NSMutableArray * array = nil;
    while (result >= 0)
    {
        SGFrame <SGFFFrame> * frame = [[SGObjectPool sharePool] objectWithClass:self.frameClass];
        result = avcodec_receive_frame(self.codecContext, frame.coreFrame);
        if (result < 0)
        {
            if (result == AVERROR(EAGAIN) || result == AVERROR_EOF) {
                
            }
            [frame unlock];
            break;
        }
        else
        {
            if (!array) {
                array = [NSMutableArray array];
            }
            [frame fillWithPacket:packet];
            [array addObject:frame];
        }
    }
    return array;
}

@end
