//
//  SGVideoFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGFFDefines.h"

@interface SGVideoFrame : SGFrame

@property (nonatomic, assign) SGAVPixelFormat format;
@property (nonatomic, assign) SGAVColorRange colorRange;
@property (nonatomic, assign) SGAVColorPrimaries colorPrimaries;
@property (nonatomic, assign) SGAVColorTransferCharacteristic colorTransferCharacteristic;
@property (nonatomic, assign) SGAVColorSpace colorSpace;
@property (nonatomic, assign) SGAVChromaLocation chromaLocation;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) BOOL keyFrame;
@property (nonatomic, assign) long long bestEffortTimestamp;
@property (nonatomic, assign) long long packetPosition;
@property (nonatomic, assign) long long packetDuration;
@property (nonatomic, assign) long long packetSize;
@property (nonatomic, assign) uint8_t ** data;
@property (nonatomic, assign) int * linesize;
@property (nonatomic, assign) CVPixelBufferRef pixelBuffer;

@end
