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

@interface SGCodecContext ()

@property (nonatomic, assign) AVCodecContext * codecContext;

@end

@implementation SGCodecContext

- (AVCodecContext *)createCcodecContext
{
    AVCodecContext * codecContext = avcodec_alloc_context3(NULL);
    if (!codecContext)
    {
        return nil;
    }
    
    int result = avcodec_parameters_to_context(codecContext, self.codecpar);
    NSError * error = SGEGetError(result);
    if (error)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    codecContext->pkt_timebase = av_make_q((int)self.timebase.value, (int)self.timebase.timescale);
    
    AVCodec * codec = avcodec_find_decoder(codecContext->codec_id);
    if (!codec)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    codecContext->codec_id = codec->id;
    
    AVDictionary * options = SGDictionaryNS2FF(self.options);
    if (self.threadsAuto &&
        !av_dict_get(options, "threads", NULL, 0))
    {
        av_dict_set(&options, "threads", "auto", 0);
    }
    if (self.refcountedFrames &&
        !av_dict_get(options, "refcounted_frames", NULL, 0) &&
        (codecContext->codec_type == AVMEDIA_TYPE_VIDEO || codecContext->codec_type == AVMEDIA_TYPE_AUDIO))
    {
        av_dict_set(&options, "refcounted_frames", "1", 0);
    }
    
    result = avcodec_open2(codecContext, codec, &options);
    error = SGEGetError(result);
    if (error)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    
    return codecContext;
}

- (void)dealloc
{
    [self close];
}

- (BOOL)open
{
    if (!self.codecpar)
    {
        return NO;
    }
    if (!self.frameClass)
    {
        return NO;
    }
    if (CMTimeCompare(self.timebase, kCMTimeZero) <= 0)
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

- (NSArray <__kindof SGFrame <SGFFFrame> *> *)decode:(SGPacket *)packet
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
        AVFrame * coreFrame = frame.coreFrame;
        NSAssert(frame, @"Fecth frame failed");
        result = avcodec_receive_frame(self.codecContext, coreFrame);
        if (result < 0)
        {
            if (result == AVERROR(EAGAIN) || result == AVERROR_EOF) {
                
            } else {
                SGPlayerLog(@"Error : %@", SGEGetErrorCode(result, SGErrorCodeCodecReceiveFrame));
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
