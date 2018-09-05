//
//  SGAudioDecoder.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioDecoder.h"
#import "SGCodecContext.h"
#import "SGAudioFFFrame.h"

@interface SGAudioDecoder ()

@property (nonatomic, strong) SGCodecContext * codecContext;

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

- (BOOL)putPacket:(SGPacket *)packet
{
    if (CMTIMERANGE_IS_VALID(packet.timeRange) &&
        !CMTimeRangeContainsTime(packet.timeRange, packet.originalTimeStamp))
    {
        return NO;
    }
    return [super putPacket:packet];
}

- (void)doSetup
{
    self.codecContext = [[SGCodecContext alloc] init];
    self.codecContext.timebase = self.timebase;
    self.codecContext.codecpar = self.codecpar;
    self.codecContext.frameClass = [SGAudioFFFrame class];
    self.codecContext.options = self.options;
    self.codecContext.threadsAuto = self.threadsAuto;
    self.codecContext.refcountedFrames = self.refcountedFrames;
    [self.codecContext open];
}

- (void)doDestory
{
    [self.codecContext close];
    self.codecContext = nil;
}

- (void)doFlush
{
    [self.codecContext flush];
}

- (NSArray <SGFrame *> *)doDecode:(SGPacket *)packet
{
    return [self.codecContext decode:packet];
}

@end
