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
@property (nonatomic, assign) SGFFVideoFrameRotateType rotateType;

@property (nonatomic, assign, readonly) BOOL hasData;
@property (nonatomic, assign, readonly) BOOL hasUpate;
@property (nonatomic, assign, readonly) BOOL hasUpdateRotateType;

- (void)updateWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)updateWithSGFFVideoFrame:(SGFFVideoFrame *)videoFrame;
- (void)didDraw;
- (void)didUpdateRotateType;
- (void)flush;

- (CVPixelBufferRef)pixelBufferForNV12;
- (SGFFAVYUVVideoFrame *)pixelBufferForYUV420;

- (NSTimeInterval)currentPosition;
- (NSTimeInterval)currentDuration;

- (SGPLFImage *)imageFromVideoFrame;

@end
