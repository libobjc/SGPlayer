//
//  SGVideoDecoder.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoDecoder.h"
#import "SGCodecContext.h"
#import "SGVideoToolBox.h"
#import "SGVideoFFFrame.h"
#import "SGFFDefinesMapping.h"

@interface SGVideoDecoder ()

@property (nonatomic, strong) SGCodecContext * codecContext;
@property (nonatomic, strong) SGVideoToolBox * videoToolBox;

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
    }
    return self;
}

- (void)doSetup
{
    BOOL videoToolBoxEnable = NO;
    CMVideoCodecType codecType = kCMVideoCodecType_H264;
    if (self.hardwareDecodeH264 &&
        self.codecpar->codec_id == AV_CODEC_ID_H264 &&
        [SGVideoToolBox supportH264])
    {
        videoToolBoxEnable = YES;
        codecType = kCMVideoCodecType_H264;
    }
    if (self.hardwareDecodeH265 &&
        self.codecpar->codec_id == AV_CODEC_ID_HEVC &&
        [SGVideoToolBox supportH265])
    {
        videoToolBoxEnable = YES;
        codecType = kCMVideoCodecType_HEVC;
    }
    if (videoToolBoxEnable)
    {
        SGVideoToolBox * videoToolBox = [[SGVideoToolBox alloc] init];
        videoToolBox.timebase = self.timebase;
        videoToolBox.codecpar = self.codecpar;
        videoToolBox.codecType = codecType;
        videoToolBox.preferredPixelFormat = SGDMPixelFormatSG2AV(self.preferredPixelFormat);
        if ([videoToolBox open])
        {
            self.videoToolBox = videoToolBox;
        }
    }
    if (!self.videoToolBox)
    {
        self.codecContext = [[SGCodecContext alloc] init];
        self.codecContext.timebase = self.timebase;
        self.codecContext.codecpar = self.codecpar;
        self.codecContext.frameClass = [SGVideoFFFrame class];
        self.codecContext.options = self.options;
        self.codecContext.threadsAuto = self.threadsAuto;
        self.codecContext.refcountedFrames = self.refcountedFrames;
        [self.codecContext open];
    }
}

- (void)doDestory
{
    [self.codecContext close];
    self.codecContext = nil;
    [self.videoToolBox close];
    self.videoToolBox = nil;
}

- (void)doFlush
{
    [self.codecContext flush];
    [self.videoToolBox flush];
}

- (NSArray <SGFrame *> *)doDecode:(SGPacket *)packet
{
    if (self.videoToolBox)
    {
        return [self.videoToolBox decode:packet];
    }
    return [self.codecContext decode:packet];
}

@end
