//
//  SGGLAVView.m
//  SGPlayer
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLAVView.h"
#import "SGAVPlayer.h"
#import "SGGLAVProgram.h"
#import "SGGLAVTexture.h"

@interface SGGLAVView ()

@property (nonatomic, strong) SGPLFDisplayLink * displayLink;
@property (nonatomic, strong) SGGLAVProgram * program;
@property (nonatomic, strong) SGGLAVTexture * texture;

@end

@implementation SGGLAVView

- (SGPLFImage *)imageFromPixelBuffer
{
    return SGPLFGLViewGetCurrentSnapshot(self);
}

- (BOOL)updateTextureAspect:(CGFloat *)aspect
{
    CVPixelBufferRef pixelBuffer = [self.displayView.sgavplayer pixelBufferAtCurrentTime];
    if (!pixelBuffer && !self.texture.hasTexture) return NO;
    
    [self.texture updateTextureWithPixelBuffer:pixelBuffer aspect:aspect needRelease:YES];
    return YES;
}

- (void)setupProgram
{
    self.program = [SGGLAVProgram program];
}

- (void)setupSubClass
{
    self.displayLink = [SGPLFDisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    self.displayLink.paused = NO;
}

- (void)displayLinkAction
{
    [self displayAsyncOnMainThread];
}

- (void)setPaused:(BOOL)paused
{
    self.displayLink.paused = paused;
}

- (BOOL)paused
{
    return self.displayLink.paused;
}

- (SGGLAVTexture *)texture
{
    if (!_texture) {
        _texture = [[SGGLAVTexture alloc] initWithContext:SGPLFGLViewGetContext(self)];
    }
    return _texture;
}

-  (void)cleanTexture
{
    self.texture = nil;
}

- (void)invalidate
{
    [self.displayLink invalidate];
}

- (void)dealloc
{
    [self invalidate];
}

@end
