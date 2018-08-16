//
//  SGVideoFFFrame.m
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoFFFrame.h"
#import "rational.h"

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

- (void)fillWithPacket:(SGPacket *)packet
{
    self.timebase = packet.timebase;
    self.offset = packet.offset;
    self.scale = packet.scale;
    self.originalTimeStamp = SGCMTimeMakeWithTimebase(av_frame_get_best_effort_timestamp(self.coreFrame), self.timebase);
    self.originalDuration = SGCMTimeMakeWithTimebase(av_frame_get_pkt_duration(self.coreFrame), self.timebase);
    self.timeStamp = CMTimeAdd(self.offset, SGCMTimeMultiply(self.originalTimeStamp, self.scale));
    self.duration = SGCMTimeMultiply(self.originalDuration, self.scale);
    self.decodeTimeStamp = packet.decodeTimeStamp;
    self.size = av_frame_get_pkt_size(self.coreFrame);
    self.format = self.coreFrame->format;
    self.pictureType = self.coreFrame->pict_type;
    self.colorRange = self.coreFrame->color_range;
    self.colorPrimaries = self.coreFrame->color_primaries;
    self.colorTransferCharacteristic = self.coreFrame->color_trc;
    self.colorSpace = self.coreFrame->colorspace;
    self.chromaLocation = self.coreFrame->chroma_location;
    self.width = self.coreFrame->width;
    self.height = self.coreFrame->height;
    self.keyFrame = self.coreFrame->key_frame;
    self.bestEffortTimestamp = av_frame_get_best_effort_timestamp(self.coreFrame);
    self.packetPosition = av_frame_get_pkt_pos(self.coreFrame);
    self.packetDuration = av_frame_get_pkt_duration(self.coreFrame);
    self.packetSize = av_frame_get_pkt_size(self.coreFrame);
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
    if (self.format == AV_PIX_FMT_YUV420P)
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

- (void)clear
{
    [super clear];
    if (_coreFrame)
    {
        av_frame_unref(_coreFrame);
    }
}

@end
