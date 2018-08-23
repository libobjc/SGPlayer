//
//  SGGLView.m
//  SGPlayer
//
//  Created by Single on 2018/1/24.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLView.h"

@interface SGGLView ()

@property (nonatomic, assign) SGGLSize displaySize;
@property (nonatomic, assign) GLuint displayFramebuffer;
@property (nonatomic, assign) GLuint displayRenderbuffer;

@end

@implementation SGGLView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.context = SGPLFGLContextAllocInit();
        SGPLGLContextSetCurrentContext(self.context);
        glClearColor(0, 0, 0, 1);
    }
    return self;
}

- (void)dealloc
{
    [self destroyFramebuffer];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    SGGLSize layerSize = {CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)};
    if (layerSize.width != self.displaySize.width ||
        layerSize.height != self.displaySize.width)
    {
        self.displaySize = layerSize;
        [self destroyFramebuffer];
        [self setupFramebuffer];
    }
}

- (BOOL)display
{
    SGPLGLContextSetCurrentContext(self.context);
    glBindFramebuffer(GL_FRAMEBUFFER, self.displayFramebuffer);
    glViewport(0, 0, self.displaySize.width * self.glScale, self.displaySize.height * self.glScale);
    BOOL success = [self.delegate glView:self draw:self.displaySize];
    if (success)
    {
        glBindRenderbuffer(GL_RENDERBUFFER, self.displayRenderbuffer);
        [self present];
        _rendered = YES;
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    return success;
}

- (void)clear
{
    SGPLGLContextSetCurrentContext(self.context);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self present];
    _rendered = NO;
}

- (void)setupFramebuffer
{
    if (self.displaySize.width == 0 ||
        self.displaySize.height == 0)
    {
        return;
    }
    SGPLGLContextSetCurrentContext(self.context);
    glGenFramebuffers(1, &_displayFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _displayFramebuffer);
    glGenRenderbuffers(1, &_displayRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, self.displayRenderbuffer);
    [self renderbufferStorage];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.displayRenderbuffer);
    _rendered = NO;
}

- (void)destroyFramebuffer
{
    SGPLGLContextSetCurrentContext(self.context);
    if (_displayFramebuffer)
    {
        glDeleteFramebuffers(1, &_displayFramebuffer);
        _displayFramebuffer = 0;
    }
    if (self.displayRenderbuffer)
    {
        glDeleteRenderbuffers(1, &_displayRenderbuffer);
        self.displayRenderbuffer = 0;
    }
    _rendered = NO;
}

@end
