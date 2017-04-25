//
//  SGGLFrame.m
//  SGPlayer
//
//  Created by Single on 2017/3/27.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGGLFrame.h"

@interface SGGLFrame ()

@property (nonatomic, assign) CVPixelBufferRef pixelBuffer;
@property (nonatomic, strong) SGFFVideoFrame * videoFrame;

@end

@implementation SGGLFrame

+ (instancetype)frame
{
    return [[self alloc] init];
}

- (void)updateWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;
{
    [self flush];
    
    self->_type = SGGLFrameTypeNV12;
    self.pixelBuffer = pixelBuffer;
    
    self->_hasData = YES;
    self->_hasUpate = YES;
}

- (void)updateWithSGFFVideoFrame:(SGFFVideoFrame *)videoFrame;
{
    [self flush];
    
    self.videoFrame = videoFrame;
    if ([videoFrame isKindOfClass:[SGFFCVYUVVideoFrame class]]) {
        self->_type = SGGLFrameTypeNV12;
    } else {
        self->_type = SGGLFrameTypeYUV420;
    }
    [self.videoFrame startPlaying];
    
    self->_hasData = YES;
    self->_hasUpate = YES;
}

- (CVPixelBufferRef)pixelBufferForNV12
{
    if (self.pixelBuffer) {
        return self.pixelBuffer;
    } else {
        return [(SGFFCVYUVVideoFrame *)self.videoFrame pixelBuffer];
    }
}

- (SGFFAVYUVVideoFrame *)pixelBufferForYUV420
{
    return (SGFFAVYUVVideoFrame *)self.videoFrame;
}

- (NSTimeInterval)currentPosition
{
    if (self.videoFrame) {
        return self.videoFrame.position;
    }
    return -1;
}

- (NSTimeInterval)currentDuration
{
    if (self.videoFrame) {
        return self.videoFrame.duration;
    }
    return -1;
}

- (SGPLFImage *)imageFromVideoFrame
{
    if ([self.videoFrame isKindOfClass:[SGFFAVYUVVideoFrame class]]) {
        SGFFAVYUVVideoFrame * frame = (SGFFAVYUVVideoFrame *)self.videoFrame;
        SGPLFImage * image = frame.image;
        if (image) return image;
    } else if ([self.videoFrame isKindOfClass:[SGFFCVYUVVideoFrame class]]) {
        SGFFCVYUVVideoFrame * frame = (SGFFCVYUVVideoFrame *)self.videoFrame;
        if (frame.pixelBuffer) {
            SGPLFImage * image = SGPLFImageWithCVPixelBuffer(frame.pixelBuffer);
            if (image) return image;
        }
    }
    return nil;
}

- (void)setRotateType:(SGFFVideoFrameRotateType)rotateType
{
    if (_rotateType != rotateType) {
        _rotateType = rotateType;
        self->_hasUpdateRotateType = YES;
    }
}

- (void)didDraw
{
    self->_hasUpate = NO;
}

- (void)didUpdateRotateType
{
    self->_hasUpdateRotateType = NO;
}

- (void)flush
{
    self->_hasData = NO;
    self->_hasUpate = NO;
    self->_hasUpdateRotateType = NO;
    if (self.pixelBuffer) {
        CVPixelBufferRelease(self.pixelBuffer);
        self.pixelBuffer = NULL;
    }
    if (self.videoFrame) {
        [self.videoFrame stopPlaying];
        self.videoFrame = nil;
    }
}

- (void)dealloc
{
    [self flush];
}

@end
