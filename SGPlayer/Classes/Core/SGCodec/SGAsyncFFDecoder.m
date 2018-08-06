//
//  SGAsyncFFDecoder.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAsyncFFDecoder.h"
#import "SGError.h"
#import "SGMacro.h"
#import "SGAudioFFFrame.h"
#import "SGVideoFFFrame.h"

@interface SGAsyncFFDecoder ()

@property (nonatomic, assign) AVCodecContext * codecContext;

@end

@implementation SGAsyncFFDecoder

+ (AVCodecContext *)ccodecContextWithCodecpar:(AVCodecParameters *)codecpar timebase:(CMTime)timebase
{
    AVCodecContext * codecContext = avcodec_alloc_context3(NULL);
    if (!codecContext)
    {
        return nil;
    }
    
    int result = avcodec_parameters_to_context(codecContext, codecpar);
    NSError * error = SGFFGetError(result);
    if (error)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    av_codec_set_pkt_timebase(codecContext, (AVRational){(int)timebase.value, (int)timebase.timescale});
    
    AVCodec * codec = avcodec_find_decoder(codecContext->codec_id);
    if (!codec)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    codecContext->codec_id = codec->id;
    
    result = avcodec_open2(codecContext, codec, NULL);
    error = SGFFGetError(result);
    if (error)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    
    return codecContext;
}

- (BOOL)open
{
    self.codecContext = [SGAsyncFFDecoder ccodecContextWithCodecpar:self.codecpar timebase:self.timebase];
    if (self.codecContext)
    {
        return [super open];
    }
    return NO;
}

- (BOOL)close
{
    if (![super close])
    {
        return NO;
    }
    if (self.codecContext)
    {
        avcodec_close(self.codecContext);
        self.codecContext = nil;
    }
    return YES;
}

- (void)doFlush
{
    [super doFlush];
    if (self.codecContext)
    {
        avcodec_flush_buffers(self.codecContext);
    }
}

- (NSArray <__kindof SGFrame *> *)doDecode:(SGPacket *)packet
{
    int result = avcodec_send_packet(self.codecContext, packet.corePacket);
    if (result < 0)
    {
        return nil;
    }
    NSMutableArray * array = nil;
    while (result >= 0)
    {
        SGFrame * frame = [self nextReuseFrame];
        AVFrame * coreFrame = NULL;
        if ([frame isKindOfClass:[SGFFAudioFFFrame class]])
        {
            coreFrame = ((SGFFAudioFFFrame *)frame).coreFrame;
        }
        else if ([frame isKindOfClass:[SGVideoFFFrame class]])
        {
            coreFrame = ((SGVideoFFFrame *)frame).coreFrame;
        }
        NSAssert(frame, @"Fecth frame failed");
        result = avcodec_receive_frame(self.codecContext, coreFrame);
        if (result < 0)
        {
            if (result == AVERROR(EAGAIN) || result == AVERROR_EOF) {
                
            } else {
                SGPlayerLog(@"Error : %@", SGFFGetErrorCode(result, SGErrorCodeCodecReceiveFrame));
            }
            [frame unlock];
            break;
        }
        else
        {
            if (!array) {
                array = [NSMutableArray array];
            }
            if ([frame isKindOfClass:[SGFFAudioFFFrame class]])
            {
                [(SGFFAudioFFFrame *)frame fillWithTimebase:self.timebase packet:packet];
            }
            else if ([frame isKindOfClass:[SGVideoFFFrame class]])
            {
                [(SGVideoFFFrame *)frame fillWithTimebase:self.timebase packet:packet];
            }
            [array addObject:frame];
        }
    }
    return array;
}

- (SGFrame *)nextReuseFrame
{
    return nil;
}

@end
