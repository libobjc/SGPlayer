//
//  SGGLFrame.h
//  SGPlayer
//
//  Created by Single on 2017/3/27.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SGPlayerBuildConfig.h"
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
@property (nonatomic, assign, readonly) BOOL hasUpdateRotateType;

- (void)didDraw;
- (void)didUpdateRotateType;
- (void)flush;

- (void)updateWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (CVPixelBufferRef)pixelBufferForNV12;

#if SGPlayerBuildConfig_FFmpeg_Enable

- (void)updateWithSGFFVideoFrame:(SGFFVideoFrame *)videoFrame;
- (SGFFAVYUVVideoFrame *)pixelBufferForYUV420;

@property (nonatomic, assign) SGFFVideoFrameRotateType rotateType;

#endif

- (NSTimeInterval)currentPosition;
- (NSTimeInterval)currentDuration;

- (SGPLFImage *)imageFromVideoFrame;

@end
