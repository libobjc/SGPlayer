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

- (void)didDraw
{
    self->_hasUpate = NO;
}

- (void)flush
{
    self->_hasData = NO;
    self->_hasUpate = NO;
    if (self.pixelBuffer) {
        CVPixelBufferRelease(self.pixelBuffer);
    }
    if (self.videoFrame) {
        [self.videoFrame stopPlaying];
    }
}

- (void)dealloc
{
    [self flush];
    NSLog(@"SGGLFrame release");
}

@end
