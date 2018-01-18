//
//  SGFFAudioCodec.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioCodec.h"
#import "SGFFPacketQueue.h"
#import "SGFFTime.h"

@interface SGFFAudioCodec ()

@property (nonatomic, strong) SGFFPacketQueue * packetQueue;

@end

@implementation SGFFAudioCodec

@synthesize processingDelegate = _processingDelegate;
@synthesize timebase = _timebase;

+ (SGFFCodecType)type
{
    return SGFFCodecTypeAudio;
}

- (void)open
{
    self.timebase = SGFFTimebaseValidate(self.timebase, 1, 44100);
    self.packetQueue = [[SGFFPacketQueue alloc] init];
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
    NSLog(@"Audio Codec Packet Queue Duration : %lld", self.packetQueue.duration);
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
    return 0;
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
    return 0;
}

@end
