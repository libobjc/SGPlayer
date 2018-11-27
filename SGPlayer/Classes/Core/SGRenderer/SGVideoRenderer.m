//
//  SGVideoRenderer.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGVideoRenderer.h"
#import "SGRenderer+Internal.h"
#import "SGVRMatrixMaker.h"
#import "SGMapping.h"
#import "SGOpenGL.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGVideoRenderer () <SGGLViewDelegate>

{
    NSLock *_lock;
    SGClock *_clock;
    SGGLTimer *_fetchTimer;
    SGGLDisplayLink *_drawTimer;
    
    SGGLView *_glView;
    SGGLModelPool *_modelPool;
    SGGLProgramPool *_programPool;
    SGVRMatrixMaker *_matrixMaker;
    SGGLTextureUploader *_glUploader;
    
    CMTime _rate;
    SGCapacity *_capacity;
    SGRenderableState _state;
    
    int _framesOutput;
    int _framesDisplayed;
    BOOL _hasNewFrameToOutput;
    BOOL _hasNewFrameToDisplay;
    SGVideoFrame *_currentFrame;
    double _frameInvalidMediaTime;
}

@end

@implementation SGVideoRenderer

@synthesize delegate = _delegate;

- (instancetype)init
{
    NSAssert(NO, @"Invalid Function.");
    return nil;
}

- (instancetype)initWithClock:(SGClock *)clock
{
    if (self = [super init]) {
        self->_clock = clock;
        self->_rate = CMTimeMake(1, 1);
        self->_lock = [[NSLock alloc] init];
        self.scalingMode = SGScalingModeResizeAspect;
        self.displayMode = SGDisplayModePlane;
        self.displayInterval = CMTimeMake(1, 30);
        self->_modelPool = [[SGGLModelPool alloc] init];
        self->_programPool = [[SGGLProgramPool alloc] init];
        self->_matrixMaker = [[SGVRMatrixMaker alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self->_fetchTimer invalidate];
    self->_fetchTimer = nil;
    [self->_drawTimer invalidate];
    self->_drawTimer = nil;
    [self->_currentFrame unlock];
    self->_currentFrame = nil;
    [self performSelectorOnMainThread:@selector(removeGLViewIfNeeded) withObject:nil waitUntilDone:YES];
}

#pragma mark - Setter & Getter

- (SGBlock)setState:(SGRenderableState)state
{
    if (self->_state == state) {
        return ^{};
    }
    self->_state = state;
    return ^{
        [self.delegate renderable:self didChangeState:state];
    };
}

- (SGRenderableState)state
{
    __block SGRenderableState ret = SGRenderableStateNone;
    SGLockEXE00(self->_lock, ^{
        ret = self->_state;
    });
    return ret;
}

- (SGCapacity *)capacity
{
    __block SGCapacity *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_capacity copy];
    });
    return ret ? ret : [[SGCapacity alloc] init];
}

- (void)setRate:(CMTime)rate
{
    SGLockEXE00(self->_lock, ^{
        self->_rate = rate;
    });
}

- (CMTime)rate
{
    __block CMTime ret = CMTimeMake(1, 1);
    SGLockEXE00(self->_lock, ^{
        ret = self->_rate;
    });
    return ret;
}

- (void)setViewport:(SGVRViewport *)viewport
{
    self->_matrixMaker.viewport = viewport;
}

- (SGVRViewport *)viewport
{
    return self->_matrixMaker.viewport;
}

- (SGPLFImage *)originalImage
{
    __block SGPLFImage *ret = nil;
    SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_currentFrame != nil;
    }, ^SGBlock {
        SGVideoFrame *frame = self->_currentFrame;
        [frame lock];
        return ^{
            ret = [frame image];
            [frame unlock];
        };
    }, ^BOOL(SGBlock block) {
        block();
        return YES;
    });
    return ret;
}

- (SGPLFImage *)snapshot
{
    return SGPLFViewGetCurrentSnapshot(self->_glView);
}

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state == SGRenderableStateNone;
    }, ^SGBlock {
        return [self setState:SGRenderableStatePaused];
    }, ^BOOL(SGBlock block) {
        block();
        SGWeakify(self)
        NSTimeInterval timeInterval = CMTimeGetSeconds(self.displayInterval);
        self->_drawTimer = [[SGGLDisplayLink alloc] initWithTimeInterval:timeInterval handler:^{
            SGStrongify(self);
            [self drawTimerHandler];
        }];
        self->_fetchTimer = [[SGGLTimer alloc] initWithTimeInterval:timeInterval / 2.0f handler:^{
            SGStrongify(self)
            [self fetchTimerHandler];
        }];
        self->_fetchTimer.paused = NO;
        self->_drawTimer.paused = NO;
        return YES;
    });
}

- (BOOL)close
{
    return SGLockEXE11(self->_lock, ^SGBlock {
        SGBlock b1 = self->_framesDisplayed ? ^{
            [self performSelectorOnMainThread:@selector(clear) withObject:nil waitUntilDone:YES];
        } : ^{};
        SGBlock b2 = [self setState:SGRenderableStateNone];
        [self->_currentFrame unlock];
        self->_currentFrame = nil;
        self->_hasNewFrameToDisplay = NO;
        self->_hasNewFrameToOutput = NO;
        self->_framesDisplayed = 0;
        self->_framesOutput = 0;
        return ^{
            b1(); b2();
        };
    }, ^BOOL(SGBlock block) {
        [self->_fetchTimer invalidate];
        self->_fetchTimer = nil;
        [self->_drawTimer invalidate];
        self->_drawTimer = nil;
        block();
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state == SGRenderableStateRendering || self->_state == SGRenderableStateFinished;
    }, ^SGBlock {
        return [self setState:SGRenderableStatePaused];
    }, ^BOOL(SGBlock block) {
        self->_drawTimer.paused = NO;
        self->_fetchTimer.paused = NO;
        return YES;
    });
}

- (BOOL)resume
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state == SGRenderableStatePaused || self->_state == SGRenderableStateFinished;
    }, ^SGBlock {
        return [self setState:SGRenderableStateRendering];
    }, ^BOOL(SGBlock block) {
        self->_drawTimer.paused = NO;
        self->_fetchTimer.paused = NO;
        return YES;
    });
}

- (BOOL)flush
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state == SGRenderableStatePaused || self->_state == SGRenderableStateRendering || self->_state == SGRenderableStateFinished;
    }, ^SGBlock {
        self->_hasNewFrameToDisplay = NO;
        self->_hasNewFrameToOutput = NO;
        self->_framesDisplayed = 0;
        self->_framesOutput = 0;
        return nil;
    }, ^BOOL(SGBlock block) {
        self->_drawTimer.paused = NO;
        self->_fetchTimer.paused = NO;
        return YES;
    });
}

- (BOOL)finish
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state == SGRenderableStateRendering || self->_state == SGRenderableStatePaused;
    }, ^SGBlock {
        return [self setState:SGRenderableStateFinished];
    }, ^BOOL(SGBlock block) {
        self->_drawTimer.paused = NO;
        self->_fetchTimer.paused = NO;
        return YES;
    });
}

#pragma mark - Render

- (void)fetchTimerHandler
{
    BOOL should_fetch = NO;
    BOOL should_pause = NO;
    [self->_lock lock];
    if (self->_state == SGRenderableStateRendering || (self->_state == SGRenderableStatePaused && self->_framesOutput == 0)) {
        should_fetch = YES;
    } else if (self->_state != SGRenderableStateRendering) {
        should_pause = YES;
    }
    [self->_lock unlock];
    if (should_pause) {
        self->_fetchTimer.paused = YES;
    }
    if (!should_fetch) {
        return;
    }
    __block double media_time_current = CACurrentMediaTime();
    SGWeakify(self)
    SGVideoFrame *ret = [self.delegate renderable:self fetchFrame:^BOOL(CMTime *desire, BOOL *drop) {
        SGStrongify(self)
        return SGLockCondEXE11(self->_lock, ^BOOL {
            return self->_currentFrame && self->_framesOutput != 0;
        }, ^SGBlock {
            return nil;
        }, ^BOOL(SGBlock block) {
            CMTime time = kCMTimeZero;
            CMTime advanced = kCMTimeZero;
            [self->_clock preferredVideoTime:&time advanced:&advanced];
            double media_time_next = [self->_drawTimer nextTimestamp];
            media_time_current = CACurrentMediaTime();
            *desire = CMTimeAdd(CMTimeAdd(time, advanced), CMTimeMaximum(SGCMTimeMakeWithSeconds(media_time_next - media_time_current), kCMTimeZero));
            *drop = YES;
            return YES;
        });
    }];
    SGLockEXE10(self->_lock, ^SGBlock {
        SGCapacity *capacity = [[SGCapacity alloc] init];
        if (ret) {
            [self->_currentFrame unlock];
            self->_currentFrame = ret;
            self->_hasNewFrameToDisplay = YES;
            self->_hasNewFrameToOutput = YES;
            self->_framesOutput += 1;
            self->_frameInvalidMediaTime = media_time_current + CMTimeGetSeconds(SGCMTimeMultiply(ret.duration, self->_rate));
            [self->_clock setVideoCurrentTime:self->_currentFrame.timeStamp];
            capacity.duration = ret.duration;
        } else if (media_time_current < self->_frameInvalidMediaTime) {
            capacity.duration = SGCMTimeMakeWithSeconds(self->_frameInvalidMediaTime - media_time_current);
        }
        SGBlock b1 = ^{};
        if (![capacity isEqualToCapacity:self->_capacity]) {
            self->_capacity = capacity;
            b1 = ^{
                [self.delegate renderable:self didChangeCapacity:[capacity copy]];
            };
        }
        return b1;
    });
}

- (void)drawTimerHandler
{
    __block BOOL draw_ret = NO;
    SGLockEXE11(self->_lock, ^SGBlock {
        SGBlock b1 = ^{}, b2 = ^{};
        if (self->_hasNewFrameToOutput && self->_currentFrame) {
            SGVideoFrame *frame = self->_currentFrame;
            [frame lock];
            b1 = ^{
                if (self.frameOutput) {
                    self.frameOutput(frame);
                }
                [frame unlock];
            };
        }
        if ((self->_hasNewFrameToDisplay || !self->_glView.framesDisplayed || (self.displayMode == SGDisplayModeVR || self.displayMode == SGDisplayModeVRBox)) && self->_currentFrame) {
            b2 = ^{
                [self addGLViewIfNeeded];
                if (self->_glView.superview && self->_glView.displaySize.width > 0) {
                    draw_ret = [self display];
                }
            };
        }
        return ^{
            b1(); b2();
        };
    }, ^BOOL(SGBlock block) {
        block();
        SGLockEXE10(self->_lock, ^SGBlock {
            self->_hasNewFrameToOutput = NO;
            if (draw_ret && self->_hasNewFrameToDisplay) {
                self->_hasNewFrameToDisplay = NO;
                self->_framesDisplayed += 1;
            }
            SGBlock b1 = ^{};
            if (self->_state != SGRenderableStateRendering && self->_displayMode == SGDisplayModePlane && self->_framesDisplayed && self->_glView.framesDisplayed) {
                b1 = ^{
                    self->_drawTimer.paused = YES;
                };
            }
            return b1;
        });
        return YES;
    });
}

#pragma mark - SGGLView

- (void)addGLViewIfNeeded
{
    if (self.view) {
        if (!self->_glView) {
            self->_glView = [[SGGLView alloc] initWithFrame:self.view.bounds];
            self->_glUploader = [[SGGLTextureUploader alloc] initWithGLContext:self->_glView.context];
            self->_glView.delegate = self;
        }
        if (self->_glView.superview != self.view) {
            SGPLFViewInsertSubview(self.view, self->_glView, 0);
            self->_glView.translatesAutoresizingMaskIntoConstraints = NO;
            NSLayoutConstraint *c1 = [NSLayoutConstraint constraintWithItem:self->_glView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
            NSLayoutConstraint *c2 = [NSLayoutConstraint constraintWithItem:self->_glView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
            NSLayoutConstraint *c3 = [NSLayoutConstraint constraintWithItem:self->_glView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
            NSLayoutConstraint *c4 = [NSLayoutConstraint constraintWithItem:self->_glView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
            [self.view addConstraints:@[c1, c2, c3, c4]];
        }
    } else {
        [self->_glView removeFromSuperview];
    }
}

- (void)removeGLViewIfNeeded
{
    [self->_glView removeFromSuperview];
}

- (BOOL)display
{
#if SGPLATFORM_TARGET_OS_IPHONE
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        return [self->_glView display];
    }
    return NO;
#else
    return [self->_glView display];
#endif
}

- (BOOL)clear
{
#if SGPLATFORM_TARGET_OS_IPHONE
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        return [self->_glView clear];
    }
    return NO;
#else
    return [self->_glView clear];
#endif
}

- (BOOL)glView:(SGGLView *)glView display:(SGGLSize)size
{
    [self->_lock lock];
    SGVideoFrame *frame = self->_currentFrame;
    if (!frame || frame.width == 0 || frame.height == 0) {
        [self->_lock unlock];
        return NO;
    }
    [frame lock];
    [self->_lock unlock];
    SGGLSize textureSize = {frame.width, frame.height};
    SGDisplayMode displayMode = self.displayMode;
    id<SGGLModel> model = [self->_modelPool modelWithType:SGDisplay2Model(displayMode)];
    id<SGGLProgram> program = [self->_programPool programWithType:SGFormat2Program(frame.format, frame.pixelBuffer)];
    if (!model || !program) {
        [frame unlock];
        return NO;
    }
    [program use];
    [program bindVariable];
    BOOL success = [self->_glUploader uploadWithVideoFrame:frame];
    if (!success) {
        [model unbind];
        [program unuse];
        [frame unlock];
        return NO;
    }
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [model bindPosition_location:program.position_location
      textureCoordinate_location:program.textureCoordinate_location];
    switch (displayMode) {
        case SGDisplayModePlane: {
            [program updateModelViewProjectionMatrix:GLKMatrix4Identity];
            [SGGLViewport updateWithLayerSize:size scale:glView.glScale textureSize:textureSize mode:SGScaling2Viewport(self.scalingMode)];
            [model draw];
        }
            break;
        case SGDisplayModeVR: {
            double aspect = (float)size.width / (float)size.height;
            GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Identity;
            if (![self->_matrixMaker matrixWithAspect:aspect matrix1:&modelViewProjectionMatrix]) {
                break;
            }
            [program updateModelViewProjectionMatrix:modelViewProjectionMatrix];
            [SGGLViewport updateWithLayerSize:size scale:glView.glScale];
            [model draw];
        }
            break;
        case SGDisplayModeVRBox: {
            double aspect = (float)size.width / (float)size.height / 2;
            GLKMatrix4 modelViewProjectionMatrix1 = GLKMatrix4Identity;
            GLKMatrix4 modelViewProjectionMatrix2 = GLKMatrix4Identity;
            if (![self->_matrixMaker matrixWithAspect:aspect matrix1:&modelViewProjectionMatrix1 matrix2:&modelViewProjectionMatrix2]) {
                break;
            }
            [program updateModelViewProjectionMatrix:modelViewProjectionMatrix1];
            [SGGLViewport updateWithLayerSizeForLeft:size scale:glView.glScale];
            [model draw];
            [program updateModelViewProjectionMatrix:modelViewProjectionMatrix2];
            [SGGLViewport updateWithLayerSizeForRight:size scale:glView.glScale];
            [model draw];
        }
            break;
    }
    [model unbind];
    [program unuse];
    [frame unlock];
    return YES;
}

- (BOOL)glView:(SGGLView *)glView clear:(SGGLSize)size
{
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    return YES;
}

- (void)glViewDidFlush:(SGGLView *)glView
{
    SGLockCondEXE00(self->_lock, ^BOOL {
        return self->_state == SGRenderableStateRendering || self->_state == SGRenderableStatePaused || self->_state == SGRenderableStateFinished;
    }, ^ {
        self->_drawTimer.paused = NO;
        self->_fetchTimer.paused = NO;
    });
}

@end
