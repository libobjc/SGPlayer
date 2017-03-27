//
//  SGGLFrame.h
//  SGPlayer
//
//  Created by Single on 2017/3/27.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SGFFVideoFrame.h"

typedef NS_ENUM(NSUInteger, SGGLFrameType) {
    SGGLFrameTypeNV12,
    SGGLFrameTypeYUV420,
};

@interface SGGLFrame : NSObject

+ (instancetype)frame;

@property (nonatomic, assign, readonly) SGGLFrameType type;

@property (nonatomic, assign, readonly) BOOL hasData;
@property (nonatomic, assign, readonly) BOOL hasUpate;

- (void)updateWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)updateWithSGFFVideoFrame:(SGFFVideoFrame *)videoFrame;
- (void)didDraw;
- (void)flush;

- (CVPixelBufferRef)pixelBufferForNV12;
- (SGFFAVYUVVideoFrame *)pixelBufferForYUV420;
- (SGPLFImage *)imageFromVideoFrame;

@end
