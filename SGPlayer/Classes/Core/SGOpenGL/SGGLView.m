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
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
@property (nonatomic, assign) GLuint displayFramebuffer;
@property (nonatomic, assign) GLuint displayRenderbuffer;
#endif

@end

@implementation SGGLView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.context = SGPLFGLContextAllocInit();
        SGPLGLContextSetCurrentContext(self.context);
        glClearColor(0, 0, 0, 1);
    }
    return self;
}

- (void)dealloc
{
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    [self destroyFramebuffer];
#endif
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    SGGLSize layerSize = {CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)};
    if (layerSize.width != self.displaySize.width ||
        layerSize.height != self.displaySize.height) {
        self.displaySize = layerSize;
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
        [self destroyFramebuffer];
        [self setupFramebuffer];
#endif
        _framesDisplayed = 0;
        [self.delegate glViewDidFlush:self];
    }
}

- (BOOL)display
{
    SGPLGLContextSetCurrentContext(self.context);
    [self prepare];
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    glBindFramebuffer(GL_FRAMEBUFFER, self.displayFramebuffer);
#endif
    glViewport(0, 0, self.displaySize.width * self.glScale, self.displaySize.height * self.glScale);
    BOOL success = [self.delegate glView:self display:self.displaySize];
    if (success) {
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
        glBindRenderbuffer(GL_RENDERBUFFER, self.displayRenderbuffer);
#endif
        [self present];
        _framesDisplayed += 1;
    }
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
#endif
    return success;
}

- (BOOL)clear
{
    SGPLGLContextSetCurrentContext(self.context);
    [self prepare];
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    glBindFramebuffer(GL_FRAMEBUFFER, self.displayFramebuffer);
#endif
    glViewport(0, 0, self.displaySize.width * self.glScale, self.displaySize.height * self.glScale);
    BOOL success = NO;
    if ([self.delegate respondsToSelector:@selector(glView:clear:)]) {
        success = [self.delegate glView:self clear:self.displaySize];
    }
    if (!success) {
        glClearColor(0, 0, 0, 1);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }
    _framesDisplayed = 0;
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    glBindRenderbuffer(GL_RENDERBUFFER, self.displayRenderbuffer);
#endif
    [self present];
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
#endif
    return YES;
}

#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
- (void)setupFramebuffer
{
    if (self.displaySize.width == 0 ||
        self.displaySize.height == 0) {
        return;
    }
    SGPLGLContextSetCurrentContext(self.context);
    glGenFramebuffers(1, &_displayFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _displayFramebuffer);
    glGenRenderbuffers(1, &_displayRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, self.displayRenderbuffer);
    [self renderbufferStorage];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.displayRenderbuffer);
}

- (void)destroyFramebuffer
{
    SGPLGLContextSetCurrentContext(self.context);
    if (_displayFramebuffer) {
        glDeleteFramebuffers(1, &_displayFramebuffer);
        _displayFramebuffer = 0;
    }
    if (self.displayRenderbuffer) {
        glDeleteRenderbuffers(1, &_displayRenderbuffer);
        self.displayRenderbuffer = 0;
    }
}
#endif

@end
