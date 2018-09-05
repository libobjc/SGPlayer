//
//  SGVideoFFFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoFFFrame.h"
#import "SGFFDefinesMapping.h"

@interface SGVideoFFFrame ()

{
    uint8_t * _resampleData[8];
    size_t _resampleDataSize[8];
    int _resampleLinesize[8];
}

@end

@implementation SGVideoFFFrame

@synthesize coreFrame = _coreFrame;

- (instancetype)init
{
    if (self = [super init])
    {
        NSLog(@"%s", __func__);
        _coreFrame = av_frame_alloc();
        for (int i = 0; i < 8; i++)
        {
            _resampleData[i] = NULL;
            _resampleDataSize[i] = 0;
            _resampleLinesize[i] = 0;
        }
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    if (_coreFrame)
    {
        av_frame_free(&_coreFrame);
        _coreFrame = NULL;
    }
    for (int i = 0; i < 8; i++)
    {
        _resampleLinesize[i] = 0;
        if (_resampleData[i] != NULL && _resampleDataSize[i] > 0)
        {
            free(_resampleData[i]);
            _resampleData[i] = NULL;
            _resampleDataSize[i] = 0;
        }
    }
}

- (void)clear
{
    [super clear];
    if (_coreFrame)
    {
        av_frame_unref(_coreFrame);
    }
}

- (void)fillWithPacket:(SGPacket *)packet
{
    self.timebase = packet.timebase;
    self.offset = packet.offset;
    self.scale = packet.scale;
    self.originalTimeStamp = SGCMTimeMakeWithTimebase(self.coreFrame->best_effort_timestamp, self.timebase);
    self.originalDuration = SGCMTimeMakeWithTimebase(self.coreFrame->pkt_duration, self.timebase);
    self.timeStamp = CMTimeAdd(self.offset, SGCMTimeMultiply(self.originalTimeStamp, self.scale));
    self.duration = SGCMTimeMultiply(self.originalDuration, self.scale);
    self.decodeTimeStamp = packet.originalDecodeTimeStamp;
    self.size = self.coreFrame->pkt_size;
    self.format = SGDMPixelFormatFF2SG(self.coreFrame->format);
    self.colorRange = SGDMColorRangeFF2SG(self.coreFrame->color_range);
    self.colorPrimaries = SGDMColorPrimariesFF2SG(self.coreFrame->color_primaries);
    self.colorTransferCharacteristic = SGDMColorTransferCharacteristicFF2SG(self.coreFrame->color_trc);
    self.colorSpace = SGDMColorSpaceFF2SG(self.coreFrame->colorspace);
    self.chromaLocation = SGDMChromaLocationFF2SG(self.coreFrame->chroma_location);
    self.width = self.coreFrame->width;
    self.height = self.coreFrame->height;
    self.keyFrame = self.coreFrame->key_frame;
    self.bestEffortTimestamp = self.coreFrame->best_effort_timestamp;
    self.packetPosition = self.coreFrame->pkt_pos;
    self.packetDuration = self.coreFrame->pkt_duration;
    self.packetSize = self.coreFrame->pkt_size;
    BOOL resample = [self resampleIfNeeded];
    self.data = resample ? _resampleData : self.coreFrame->data;
    self.linesize = resample ? _resampleLinesize : self.coreFrame->linesize;
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
        if (self.coreFrame->linesize[i] > linesize[i])
        {
            resample = YES;
            size_t size = linesize[i] * linecount[i] * sizeof(uint8_t);
            if (_resampleDataSize[i] < size)
            {
                if (_resampleData[i] != NULL && _resampleDataSize[i] > 0)
                {
                    free(_resampleData[i]);
                    _resampleData[i] = NULL;
                    _resampleDataSize[i] = 0;
                }
                _resampleData[i] = malloc(size);
                _resampleDataSize[i] = size;
            }
            uint8_t * dest = _resampleData[i];
            uint8_t * src = self.coreFrame->data[i];
            for (int j = 0; j < linecount[i]; j++)
            {
                memcpy(dest, src, linesize[i] * sizeof(uint8_t));
                dest += linesize[i];
                src += self.coreFrame->linesize[i];
            }
            _resampleLinesize[i] = linesize[i];
        }
    }
    return resample;
}

@end
