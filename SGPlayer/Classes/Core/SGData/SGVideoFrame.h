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

@property (nonatomic, assign, readonly) SGAVPixelFormat format;
@property (nonatomic, assign, readonly) SGAVColorRange colorRange;
@property (nonatomic, assign, readonly) SGAVColorPrimaries colorPrimaries;
@property (nonatomic, assign, readonly) SGAVColorTransferCharacteristic colorTransferCharacteristic;
@property (nonatomic, assign, readonly) SGAVColorSpace colorSpace;
@property (nonatomic, assign, readonly) SGAVChromaLocation chromaLocation;
@property (nonatomic, assign, readonly) int width;
@property (nonatomic, assign, readonly) int height;
@property (nonatomic, assign, readonly) BOOL keyFrame;
@property (nonatomic, assign, readonly) uint8_t ** data;
@property (nonatomic, assign, readonly) int * linesize;
@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;
@property (nonatomic, strong, readonly) UIImage * image;

@end
