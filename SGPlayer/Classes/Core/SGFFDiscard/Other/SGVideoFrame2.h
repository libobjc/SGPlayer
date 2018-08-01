//
//  SGVideoFrame.h
//  SGPlayer
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFrame2.h"
#import <AVFoundation/AVFoundation.h>
#import "SGPlatform.h"
#import "avformat.h"
#import "pixfmt.h"

typedef NS_ENUM(int, SGYUVChannel) {
    SGYUVChannelLuma = 0,
    SGYUVChannelChromaB = 1,
    SGYUVChannelChromaR = 2,
    SGYUVChannelCount = 3,
};

typedef NS_ENUM(NSUInteger, SGVideoFrameRotateType) {
    SGVideoFrameRotateType0,
    SGVideoFrameRotateType90,
    SGVideoFrameRotateType180,
    SGVideoFrameRotateType270,
};

@interface SGVideoFrame2 : SGFrame2

@property (nonatomic, assign) SGVideoFrameRotateType rotateType;

@end


// FFmpeg AVFrame YUV frame
@interface SGFFAVYUVVideoFrame : SGVideoFrame2

{
@public
    UInt8 * channel_pixels[SGYUVChannelCount];
}

@property (nonatomic, assign, readonly) int width;
@property (nonatomic, assign, readonly) int height;

+ (instancetype)videoFrame;
- (void)setFrameData:(AVFrame *)frame width:(int)width height:(int)height;

- (SGPLFImage *)image;

@end


// CoreVideo YUV frame
@interface SGFFCVYUVVideoFrame : SGVideoFrame2

@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
