//
//  SGFFAudioCodec.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioCodec.h"
#import "SGFFFrameQueue.h"
#import "SGFFPacketQueue.h"
#import "SGFFTime.h"

@interface SGFFAudioCodec ()

@property (nonatomic, strong) SGFFFrameQueue * frameQueue;
@property (nonatomic, strong) SGFFPacketQueue * packetQueue;

@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSInvocationOperation * decodeOperation;

@end

@implementation SGFFAudioCodec

@synthesize processingDelegate = _processingDelegate;
@synthesize timebase = _timebase;

+ (SGFFCodecType)type
{
    return SGFFCodecTypeAudio;
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
                    NSLog(@"Audio Frame PTS : %lld", av_frame_get_best_effort_timestamp(decodedFrame));
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

- (void)open
{
    self.timebase = SGFFTimebaseValidate(self.timebase, 1, 44100);
    self.frameQueue = [[SGFFFrameQueue alloc] init];
    self.packetQueue = [[SGFFPacketQueue alloc] init];
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;
    self.operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    
    self.decodeOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeThread) object:nil];
    self.decodeOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.decodeOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.operationQueue addOperation:self.decodeOperation];
}

- (void)close
{
    if (self.codecContext)
    {
        avcodec_close(self.codecContext);
        self.codecContext = nil;
    }
}

- (void)putPacket:(AVPacket)packet
{
    [self.packetQueue putPacket:packet];
}

- (long long)duration
{
    return [self packetDuration] + [self frameDuration];
}

- (long long)packetDuration
{
    return self.packetQueue.duration;
}

- (long long)frameDuration
{
    return self.frameQueue.duration;
}

- (long long)size
{
    return [self packetSize] + [self frameSize];
}

- (long long)packetSize
{
    return self.packetQueue.size;
}

- (long long)frameSize
{
    return self.frameQueue.size;
}

@end
