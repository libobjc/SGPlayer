//
//  SGVideoFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGVideoFrame.h"
#import "SGSWSContext.h"
#import "SGPlatform.h"
#import "imgutils.h"
#import "frame.h"
#import "SGTime.h"

@interface SGVideoFrame ()

@end

@implementation SGVideoFrame

- (SGMediaType)mediaType
{
    return SGMediaTypeVideo;
}

- (instancetype)init
{
    if (self = [super init])
    {
        NSLog(@"%s", __func__);
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
}

- (void)clear
{
    [super clear];
    
    self.format = SG_AV_PIX_FMT_NONE;
    self.colorRange = SG_AVCOL_RANGE_UNSPECIFIED;
    self.colorPrimaries = SG_AVCOL_PRI_RESERVED0;
    self.colorTransferCharacteristic = SG_AVCOL_TRC_RESERVED0;
    self.colorSpace = SG_AVCOL_SPC_RGB;
    self.chromaLocation = SG_AVCHROMA_LOC_UNSPECIFIED;
    self.width = 0;
    self.height = 0;
    self.keyFrame = 0;
    self.bestEffortTimestamp = 0;
    self.packetPosition = 0;
    self.packetDuration = 0;
    self.packetSize = 0;
    self.data = NULL;
    self.linesize = NULL;
    self.pixelBuffer = NULL;
}

- (void)setPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (pixelBuffer)
    {
        CVPixelBufferRetain(pixelBuffer);
    }
    if (_pixelBuffer)
    {
        CVPixelBufferRelease(_pixelBuffer);
    }
    _pixelBuffer = pixelBuffer;
}

- (UIImage *)image
{
    if (self.width == 0 ||
        self.height == 0 ||
        !self.data)
    {
        return nil;
    }
    if (!self.data[0])
    {
        return nil;
    }
    SGSWSContext * context = [[SGSWSContext alloc] init];
    context.srcFormat = self.format;
    context.dstFormat = AV_PIX_FMT_RGB24;
    context.width = self.width;
    context.height = self.height;
    if (![context open])
    {
        return nil;
    }
    uint8_t * data[AV_NUM_DATA_POINTERS] = {NULL};
    int linesize[AV_NUM_DATA_POINTERS] = {0};
    int result = av_image_alloc(data,
                                linesize,
                                self.width,
                                self.height,
                                AV_PIX_FMT_RGB24,
                                1);
    if (result < 0)
    {
        return nil;
    }
    result = [context scaleWithSrcData:(const uint8_t **)self.data
                           srcLinesize:self.linesize
                               dstData:data
                           dstLinesize:linesize];
    if (result < 0)
    {
        return nil;
    }
    if (linesize[0] <= 0 || data[0] == NULL)
    {
        return nil;
    }
    SGPLFImage * image = SGPLFImageWithRGBData(data[0], linesize[0], self.width, self.height);
    av_freep(data);
    return image;
}

@end
