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
@property (nonatomic, strong) SGStream * stream;

@end

@implementation SGVideoDecoder

- (instancetype)init
{
    if (self = [super init])
    {
        self.options = nil;
        self.threadsAuto = YES;
        self.refcountedFrames = YES;
        self.hardwareDecodeH264 = YES;
        self.hardwareDecodeH265 = YES;
        self.preferredPixelFormat = AV_PIX_FMT_NV12;
    }
    return self;
}

- (void)setup
{
    self.codecContext = [[SGCodecContext alloc] initWithStream:self.stream frameClass:[SGVideoFrame class]];
    self.codecContext.options = self.options;
    self.codecContext.threadsAuto = self.threadsAuto;
    self.codecContext.refcountedFrames = self.refcountedFrames;
    self.codecContext.hardwareDecodeH264 = self.hardwareDecodeH264;
    self.codecContext.hardwareDecodeH265 = self.hardwareDecodeH265;
    self.codecContext.preferredPixelFormat = self.preferredPixelFormat;
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
