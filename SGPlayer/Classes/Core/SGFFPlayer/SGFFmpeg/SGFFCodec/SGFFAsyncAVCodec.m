//
//  SGFFAsyncAVCodec.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAsyncAVCodec.h"
#import "SGFFError.h"

@interface SGFFAsyncAVCodec ()

@property (nonatomic, assign) AVCodecContext * codecContext;

@end

@implementation SGFFAsyncAVCodec

+ (AVCodecContext *)ccodecContextWithCodecpar:(AVCodecParameters *)codecpar timebase:(AVRational)timebase
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
    av_codec_set_pkt_timebase(codecContext, timebase);
    
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
    self.codecContext = [SGFFAsyncAVCodec ccodecContextWithCodecpar:self.codecpar timebase:self.timebase];
    if (self.codecContext)
    {
        return [super open];
    }
    return NO;
}

- (void)close
{
    [super close];
    if (self.codecContext)
    {
        avcodec_close(self.codecContext);
        self.codecContext = nil;
    }
}

- (void)decodeThread
{
    AVFrame * decodedFrame = av_frame_alloc();
    while (YES)
    {
        AVPacket packet = [self.packetQueue getPacketSync];
        if (packet.data)
        {
            int result = avcodec_send_packet(self.codecContext, &packet);
            if (result < 0 && result != AVERROR(EAGAIN) && result != AVERROR_EOF)
            {
                continue;
            }
            while (result >= 0)
            {
                result = avcodec_receive_frame(self.codecContext, decodedFrame);
                if (result < 0)
                {
                    if (result != AVERROR(EAGAIN) && result != AVERROR_EOF)
                    {
                        continue;
                    }
                    break;
                }
                @autoreleasepool
                {
                    id <SGFFFrame> frame = nil;
                    [self processingFrame:frame];
                }
            }
            av_packet_unref(&packet);
        }
        else
        {
            break;
        }
    }
    av_free(decodedFrame);
}

- (id <SGFFFrame>)frameWithDecodedFrame:(AVFrame *)decodedFrame {return nil;}

@end
