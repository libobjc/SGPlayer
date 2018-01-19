//
//  SGFFAsyncAVCodec.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAsyncAVCodec.h"

@implementation SGFFAsyncAVCodec

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
                    if ([self.processingDelegate respondsToSelector:@selector(codec:processingDecodedFrame:)])
                    {
                        id <SGFFFrame> frame = [self.processingDelegate codec:self processingDecodedFrame:decodedFrame];
                        if (frame)
                        {
                            [self.frameQueue putFrameSync:frame];
                        }
                    }
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

- (void)close
{
    [super close];
    if (self.codecContext)
    {
        avcodec_close(self.codecContext);
        self.codecContext = nil;
    }
}

@end
