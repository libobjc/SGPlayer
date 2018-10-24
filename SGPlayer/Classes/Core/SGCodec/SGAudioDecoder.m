//
//  SGAudioDecoder.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioDecoder.h"
#import "SGCodecContext.h"
#import "SGAudioFrame.h"

@interface SGAudioDecoder ()

@property (nonatomic, strong) SGCodecContext * codecContext;
@property (nonatomic, strong) SGStream * stream;

@end

@implementation SGAudioDecoder

- (instancetype)init
{
    if (self = [super init])
    {
        self.options = nil;
        self.threadsAuto = YES;
        self.refcountedFrames = YES;
    }
    return self;
}

- (void)setup
{
    self.codecContext = [[SGCodecContext alloc] initWithStream:self.stream frameClass:[SGAudioFrame class]];
    self.codecContext.options = self.options;
    self.codecContext.threadsAuto = self.threadsAuto;
    self.codecContext.refcountedFrames = self.refcountedFrames;
    [self.codecContext open];
}

- (void)destory
{
    [self.codecContext close];
    self.codecContext = nil;
}

- (NSArray <__kindof SGFrame *> *)decode:(SGPacket *)packet
{
    if (self.stream != packet.stream)
    {
        self.stream = packet.stream;
        [self destory];
        [self setup];
    }
    return [self.codecContext decode:packet];
}

- (void)flush
{
    [self.codecContext flush];
}

@end
