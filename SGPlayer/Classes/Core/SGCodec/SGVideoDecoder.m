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
#import "SGMapping.h"

@interface SGVideoDecoder ()

@property (nonatomic, strong) SGCodecContext * codecContext;
@property (nonatomic, strong) SGTrack * track;

@end

@implementation SGVideoDecoder

- (SGMediaType)type
{
    return SGMediaTypeVideo;
}

- (void)setup
{
    self.codecContext = [[SGCodecContext alloc] initWithTrack:self.track frameClass:[SGVideoFrame class]];
    [self.codecContext open];
}

- (void)destroy
{
    [self.codecContext close];
    self.codecContext = nil;
}

- (NSArray <__kindof SGFrame *> *)decode:(SGPacket *)packet
{
    if (packet && packet.track != self.track)
    {
        self.track = packet.track;
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
