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
    uint8_t * _resampleData[8];
    size_t _resampleDataSize[8];
    int _resampleLinesize[8];
}

@end

@implementation SGVideoFrame

@synthesize image = _image;

- (instancetype)init
{
    if (self = [super init])
    {
        NSLog(@"%s", __func__);
        
        for (int i = 0; i < 8; i++)
        {
            _resampleData[i] = nil;
            _resampleDataSize[i] = 0;
            _resampleLinesize[i] = 0;
        }
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    
    for (int i = 0; i < 8; i++)
    {
        _resampleLinesize[i] = 0;
        if (_resampleData[i] != nil && _resampleDataSize[i] > 0)
        {
            free(_resampleData[i]);
            _resampleData[i] = nil;
            _resampleDataSize[i] = 0;
        }
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
    _data = nil;
    _linesize = nil;
    _pixelBuffer = nil;
    _image = nil;
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
    if ([self resampleIfNeeded]) {
        _data = _resampleData;
        _linesize = _resampleLinesize;
    } else {
        _data = self.core->data;
        _linesize = self.core->linesize;
    }
    if (self.format == SG_AV_PIX_FMT_VIDEOTOOLBOX) {
        _pixelBuffer = (CVPixelBufferRef)(self.data[3]);
    }
}

- (BOOL)resampleIfNeeded
{
    BOOL resample = NO;
    int channels = 0;
    int linesize[8] = {0};
    int linecount[8] = {0};
    if (self.format == SG_AV_PIX_FMT_YUV420P)
    {
        channels = 3;
        linesize[0] = self.width;
        linesize[1] = self.width / 2;
        linesize[2] = self.width / 2;
        linecount[0] = self.height;
        linecount[1] = self.height / 2;
        linecount[2] = self.height / 2;
    }
    for (int i = 0; i < channels; i++)
    {
        if (self.core->linesize[i] > linesize[i])
        {
            resample = YES;
            size_t size = linesize[i] * linecount[i] * sizeof(uint8_t);
            if (_resampleDataSize[i] < size)
            {
                if (_resampleData[i] != nil && _resampleDataSize[i] > 0)
                {
                    free(_resampleData[i]);
                    _resampleData[i] = nil;
                    _resampleDataSize[i] = 0;
                }
                _resampleData[i] = malloc(size);
                _resampleDataSize[i] = size;
            }
            uint8_t * dest = _resampleData[i];
            uint8_t * src = self.core->data[i];
            for (int j = 0; j < linecount[i]; j++)
            {
                memcpy(dest, src, linesize[i] * sizeof(uint8_t));
                dest += linesize[i];
                src += self.core->linesize[i];
            }
            _resampleLinesize[i] = linesize[i];
        }
    }
    return resample;
}

- (UIImage *)image
{
    if (!_image)
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
        uint8_t * data[AV_NUM_DATA_POINTERS] = {nil};
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
        if (linesize[0] <= 0 || data[0] == nil)
        {
            return nil;
        }
        SGPLFImage * image = SGPLFImageWithRGBData(data[0], linesize[0], self.width, self.height);
        av_freep(data);
        _image = image;
    }
    return _image;
}

@end
