//
//  SGVideoFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGVideoFrame.h"
#import "SGFrame+Private.h"
#import "SGFFDefinesMapping.h"
#import "SGSWSContext.h"
#import "SGPlatform.h"
#import "imgutils.h"
#import "frame.h"
#import "SGTime.h"

@interface SGVideoFrame ()

{
    AVBufferRef * _buffer[SGFramePlaneCount];
}

@end

@implementation SGVideoFrame

- (instancetype)init
{
    if (self = [super init])
    {
        NSLog(@"%s", __func__);

        for (int i = 0; i < 8; i++)
        {
            _buffer[i] = nil;
        }
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    
    for (int i = 0; i < 8; i++)
    {
        av_buffer_unref(&_buffer[i]);
        _buffer[i] = nil;
    }
}

- (void)clear
{
    [super clear];
    
    _format = SG_AV_PIX_FMT_NONE;
    _colorRange = SG_AVCOL_RANGE_UNSPECIFIED;
    _colorPrimaries = SG_AVCOL_PRI_RESERVED0;
    _colorTransferCharacteristic = SG_AVCOL_TRC_RESERVED0;
    _colorSpace = SG_AVCOL_SPC_RGB;
    _chromaLocation = SG_AVCHROMA_LOC_UNSPECIFIED;
    _width = 0;
    _height = 0;
    _keyFrame = 0;
    for (int i = 0; i < SGFramePlaneCount; i++)
    {
        self->data[i] = nil;
        self->linesize[i] = 0;
    }
    self->pixelBuffer = nil;
}

- (void)configurateWithStream:(SGStream *)stream
{
    [super configurateWithStream:stream];
    
    _format = SGDMPixelFormatFF2SG(self.core->format);
    _colorRange = SGDMColorRangeFF2SG(self.core->color_range);
    _colorPrimaries = SGDMColorPrimariesFF2SG(self.core->color_primaries);
    _colorTransferCharacteristic = SGDMColorTransferCharacteristicFF2SG(self.core->color_trc);
    _colorSpace = SGDMColorSpaceFF2SG(self.core->colorspace);
    _chromaLocation = SGDMChromaLocationFF2SG(self.core->chroma_location);
    _width = self.core->width;
    _height = self.core->height;
    _keyFrame = self.core->key_frame;
    [self fillData];
}

- (void)fillData
{
    BOOL resample = NO;
    int planes = 0;
    int linesize[8] = {0};
    int linecount[8] = {0};
    if (self.format == SG_AV_PIX_FMT_YUV420P)
    {
        planes = 3;
        linesize[0] = self.width;
        linesize[1] = self.width / 2;
        linesize[2] = self.width / 2;
        linecount[0] = self.height;
        linecount[1] = self.height / 2;
        linecount[2] = self.height / 2;
    }
    else if (self.format == SG_AV_PIX_FMT_VIDEOTOOLBOX)
    {
        self->pixelBuffer = (CVPixelBufferRef)(self.core->data[3]);
    }
    for (int i = 0; i < planes; i++)
    {
        resample = resample || (self.core->linesize[i] != linesize[i]);
    }
    if (resample)
    {
        for (int i = 0; i < planes; i++)
        {
            int size = linesize[i] * linecount[i] * sizeof(uint8_t);
            if (!_buffer[i] || _buffer[i]->size < size)
            {
                av_buffer_realloc(&_buffer[i], size);
            }
            av_image_copy_plane(_buffer[i]->data,
                                linesize[i],
                                self.core->data[i],
                                self.core->linesize[i],
                                linesize[i] * sizeof(uint8_t),
                                linecount[i]);
        }
        for (int i = 0; i < planes; i++)
        {
            self->data[i] = _buffer[i]->data;
            self->linesize[i] = linesize[i];
        }
    }
    else
    {
        for (int i = 0; i < SGFramePlaneCount; i++)
        {
            self->data[i] = self.core->data[i];
            self->linesize[i] = self.core->linesize[i];
        }
    }
}

- (UIImage *)image
{
    if (self.width == 0 ||
        self.height == 0 ||
        !self->data)
    {
        return nil;
    }
    if (!self->data[0])
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
    uint8_t * data[SGFramePlaneCount] = {nil};
    int linesize[SGFramePlaneCount] = {0};
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
    result = [context scaleWithSrcData:(const uint8_t **)self->data
                           srcLinesize:self->linesize
                               dstData:data
                           dstLinesize:linesize];
    if (result < 0)
    {
        return nil;
    }
    if (linesize[0] <= 0 || data[0] == nil)
    {
        return nil;
    }
    SGPLFImage * image = SGPLFImageWithRGBData(data[0], linesize[0], self.width, self.height);
    av_freep(data);
    return image;
}

@end
