//
//  SGFFVideoFrame.h
//  SGPlayer
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFFFrame.h"
#import <AVFoundation/AVFoundation.h>
#import <SGPlatform/SGPlatform.h>
#import "avformat.h"
#import "pixfmt.h"

typedef NS_ENUM(int, SGYUVChannel) {
    SGYUVChannelLuma = 0,
    SGYUVChannelChromaB = 1,
    SGYUVChannelChromaR = 2,
    SGYUVChannelCount = 3,
};

typedef NS_ENUM(NSUInteger, SGFFVideoFrameRotateType) {
    SGFFVideoFrameRotateType0,
    SGFFVideoFrameRotateType90,
    SGFFVideoFrameRotateType180,
    SGFFVideoFrameRotateType270,
};

@interface SGFFVideoFrame : SGFFFrame

@property (nonatomic, assign) SGFFVideoFrameRotateType rotateType;

@end


// FFmpeg AVFrame YUV frame
@interface SGFFAVYUVVideoFrame : SGFFVideoFrame

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
@interface SGFFCVYUVVideoFrame : SGFFVideoFrame

@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
