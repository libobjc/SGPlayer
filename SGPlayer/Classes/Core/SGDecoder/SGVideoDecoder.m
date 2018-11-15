//
//  SGVideoDecoder.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoDecoder.h"
#import "SGCodecContext.h"
#import "SGVideoFrame.h"

@interface SGVideoDecoder ()

@property (nonatomic, strong) SGCodecContext * codecContext;
@property (nonatomic) AVCodecParameters * codecpar;
@property (nonatomic) AVRational timebase;

@end

@implementation SGVideoDecoder

- (SGMediaType)type
{
    return SGMediaTypeVideo;
}

- (void)setup
{
    self.codecContext = [[SGCodecContext alloc] initWithTimebase:self.timebase codecpar:self.codecpar frameClass:[SGVideoFrame class]];
    [self.codecContext open];
}

- (void)destroy
{
    [self.codecContext close];
    self.codecContext = nil;
}

- (NSArray <__kindof SGFrame *> *)decode:(SGPacket *)packet
{
    if (packet && (packet.codecpar != self.codecpar || av_cmp_q(packet.timebase, self.timebase) != 0)) {
        self.codecpar = packet.codecpar;
        self.timebase = packet.timebase;
        [self destroy];
        [self setup];
    }
    return [self.codecContext decode:packet];
}

- (void)flush
{
    [self.codecContext flush];
}

@end
