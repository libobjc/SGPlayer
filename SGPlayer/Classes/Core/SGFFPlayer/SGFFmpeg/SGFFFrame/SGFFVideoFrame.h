//
//  SGFFVideoFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFFrameInternal.h"
#import <AVFoundation/AVFoundation.h>


typedef NS_ENUM(NSUInteger, SGFFVideoFrameDataType)
{
    SGFFVideoFrameDataTypeAVFrame,
    SGFFVideoFrameDataTypeCVPixelBuffer,
};


@interface SGFFVideoFrame : SGFFFrameInternal

@property (nonatomic, assign, readonly) SGFFFrameType type;
@property (nonatomic, assign) SGFFTimebase timebase;
@property (nonatomic, assign) enum AVPixelFormat format;
@property (nonatomic, assign) enum AVPictureType pictureType;
@property (nonatomic, assign)enum AVColorRange colorRange;
@property (nonatomic, assign)enum AVColorPrimaries colorPrimaries;
@property (nonatomic, assign)enum AVColorTransferCharacteristic colorTransferCharacteristic;
@property (nonatomic, assign)enum AVColorSpace colorSpace;
@property (nonatomic, assign)enum AVChromaLocation chromaLocation;
@property (nonatomic, assign) AVRational sampleAspectRatio;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) BOOL keyFrame;
@property (nonatomic, assign) long long position;
@property (nonatomic, assign) long long duration;
@property (nonatomic, assign) long long size;
@property (nonatomic, assign) long long bestEffortTimestamp;
@property (nonatomic, assign) long long packetPosition;
@property (nonatomic, assign) long long packetDuration;
@property (nonatomic, assign) long long packetSize;
@property (nonatomic, assign) uint8_t ** data;
@property (nonatomic, assign) int * linesize;


- (SGFFVideoFrameDataType)dataType;
- (void)updateDataType:(SGFFVideoFrameDataType)dataType;
- (AVFrame *)coreFrame;
- (CVPixelBufferRef)corePixelBuffer;
- (void)updateCorePixelBuffer:(CVPixelBufferRef)corePixelBuffer;

@end
