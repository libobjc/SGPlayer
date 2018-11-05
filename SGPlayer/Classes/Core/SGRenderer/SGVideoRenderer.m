//
//  SGVideoRenderer.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGVideoRenderer.h"
#import "SGRenderer+Internal.h"
#import "SGGLDisplayLink.h"
#import "SGGLProgramPool.h"
#import "SGVRMatrixMaker.h"
#import "SGGLModelPool.h"
#import "SGGLTimer.h"
#import "SGMapping.h"
#import "SGGLView.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGVideoRenderer () <SGGLViewDelegate>

{
    SGRenderableState _state;
    int32_t _is_update_frame_draw;
    int32_t _is_update_frame_output;
    int64_t _nb_frames_draw;
    int64_t _nb_frames_fetch;
    double _media_time_timeout;
    CMTime _rate;
    __strong SGCapacity * _capacity;
    __strong SGVideoFrame * _current_frame;
}

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) SGClock * clock;
@property (nonatomic, strong) SGGLTimer * fetchTimer;
@property (nonatomic, strong) SGGLDisplayLink * drawTimer;
@property (nonatomic, strong) SGGLView * glView;
@property (nonatomic, strong) SGGLModelPool * modelPool;
@property (nonatomic, strong) SGGLProgramPool * programPool;
@property (nonatomic, strong) SGVRMatrixMaker * matrixMaker;
@property (nonatomic, strong) SGGLTextureUploader * glUploader;

@end

@implementation SGVideoRenderer

@synthesize object = _object;
@synthesize delegate = _delegate;

- (instancetype)initWithClock:(SGClock *)clock
{
    if (self = [super init]) {
        self.clock = clock;
        self->_rate = CMTimeMake(1, 1);
        self.lock = [[NSLock alloc] init];
        self.scalingMode = SGScalingModeResizeAspect;
        self.displayMode = SGDisplayModePlane;
        self.displayInterval = CMTimeMake(1, 30);
        self.modelPool = [[SGGLModelPool alloc] init];
        self.programPool = [[SGGLProgramPool alloc] init];
        self.matrixMaker = [[SGVRMatrixMaker alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self.fetchTimer invalidate];
    self.fetchTimer = nil;
    [self.drawTimer invalidate];
    self.drawTimer = nil;
    [self->_current_frame unlock];
    self->_current_frame = nil;
    [self performSelectorOnMainThread:@selector(removeGLViewIfNeeded) withObject:nil waitUntilDone:YES];
}

#pragma mark - Setter & Getter

- (SGBlock)setState:(SGRenderableState)state
{
    if (_state == state) {
        return ^{};
    }
    _state = state;
    return ^{
        [self.delegate renderable:self didChangeState:state];
    };
}

- (SGRenderableState)state
{
    __block SGRenderableState ret = SGRenderableStateNone;
    SGLockEXE00(self.lock, ^{
        ret = self->_state;
    });
    return ret;
}

- (SGCapacity *)capacity
{
    __block SGCapacity * ret = nil;
    SGLockEXE00(self.lock, ^{
        ret = [self->_capacity copy];
    });
    return ret ? ret : [[SGCapacity alloc] init];
}

- (void)setRate:(CMTime)rate
{
    SGLockEXE00(self.lock, ^{
        self->_rate = rate;
    });
}

- (CMTime)rate
{
    __block CMTime ret = CMTimeMake(1, 1);
    SGLockEXE00(self.lock, ^{
        ret = self->_rate;
    });
    return ret;
}

- (void)setViewport:(SGVRViewport *)viewport
{
    self.matrixMaker.viewport = viewport;
}

- (SGVRViewport *)viewport
{
    return self.matrixMaker.viewport;
}

- (UIImage *)originalImage
{
    __block UIImage * ret = nil;
    SGLockCondEXE11(self.lock, ^BOOL {
        return self->_current_frame != nil;
    }, ^SGBlock {
        SGVideoFrame * frame = self->_current_frame;
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

- (UIImage *)snapshot
{
    CGSize size = CGSizeMake(self.glView.displaySize.width,
                             self.glView.displaySize.height);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [self.glView drawViewHierarchyInRect:rect afterScreenUpdates:YES];
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state == SGRenderableStateNone;
    }, ^SGBlock {
        return [self setState:SGRenderableStatePaused];
    }, ^BOOL(SGBlock block) {
        block();
        SGWeakify(self)
        NSTimeInterval timeInterval = CMTimeGetSeconds(self.displayInterval);
        self.drawTimer = [[SGGLDisplayLink alloc] initWithTimeInterval:timeInterval handler:^{
            SGStrongify(self);
            [self drawTimerHandler];
        }];
        self.fetchTimer = [[SGGLTimer alloc] initWithTimeInterval:timeInterval / 2.0f handler:^{
            SGStrongify(self)
            [self fetchTimerHandler];
        }];
        self.fetchTimer.paused = NO;
        self.drawTimer.paused = NO;
        return YES;
    });
}

- (BOOL)close
{
    return SGLockEXE11(self.lock, ^SGBlock {
        SGBlock b1 = self->_nb_frames_draw ? ^{
            [self performSelectorOnMainThread:@selector(clear) withObject:nil waitUntilDone:YES];
        } : ^{};
        SGBlock b2 = [self setState:SGRenderableStateNone];
        [self->_current_frame unlock];
        self->_current_frame = nil;
        self->_is_update_frame_draw = 0;
        self->_is_update_frame_output = 0;
        self->_nb_frames_draw = 0;
        self->_nb_frames_fetch = 0;
        return ^{
            b1(); b2();
        };
    }, ^BOOL(SGBlock block) {
        [self.fetchTimer invalidate];
        self.fetchTimer = nil;
        [self.drawTimer invalidate];
        self.drawTimer = nil;
        block();
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state == SGRenderableStateRendering || self->_state == SGRenderableStateFinished;
    }, ^SGBlock {
        return [self setState:SGRenderableStatePaused];
    }, ^BOOL(SGBlock block) {
        self.drawTimer.paused = NO;
        self.fetchTimer.paused = NO;
        return YES;
    });
}

- (BOOL)resume
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state == SGRenderableStatePaused || self->_state == SGRenderableStateFinished;
    }, ^SGBlock {
        return [self setState:SGRenderableStateRendering];
    }, ^BOOL(SGBlock block) {
        self.drawTimer.paused = NO;
        self.fetchTimer.paused = NO;
        return YES;
    });
}

- (BOOL)finish
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state == SGRenderableStateRendering || self->_state == SGRenderableStatePaused;
    }, ^SGBlock {
        return [self setState:SGRenderableStateFinished];
    }, ^BOOL(SGBlock block) {
        self.drawTimer.paused = NO;
        self.fetchTimer.paused = NO;
        return YES;
    });
}

- (BOOL)flush
{
    return SGLockCondEXE11(self.lock, ^BOOL {
        return self->_state == SGRenderableStatePaused || self->_state == SGRenderableStateRendering || self->_state == SGRenderableStateFinished;
    }, ^SGBlock {
        self->_is_update_frame_draw = 0;
        self->_is_update_frame_output = 0;
        self->_nb_frames_draw = 0;
        self->_nb_frames_fetch = 0;
        return nil;
    }, ^BOOL(SGBlock block) {
        self.drawTimer.paused = NO;
        self.fetchTimer.paused = NO;
        return YES;
    });
}

#pragma mark - Render

- (void)fetchTimerHandler
{
    BOOL should_fetch = NO;
    BOOL should_pause = NO;
    [self.lock lock];
    if (self->_state == SGRenderableStateRendering || (self->_state == SGRenderableStatePaused && self->_nb_frames_fetch == 0)) {
        should_fetch = YES;
    } else if (self->_state != SGRenderableStateRendering) {
        should_pause = YES;
    }
    [self.lock unlock];
    if (should_pause) {
        self.fetchTimer.paused = YES;
    }
    if (!should_fetch) {
        return;
    }
    __block double media_time_current = CACurrentMediaTime();
    SGWeakify(self)
    SGVideoFrame * ret = [self.delegate renderable:self fetchFrame:^BOOL(CMTime * current, CMTime * desire, BOOL * drop) {
        SGStrongify(self)
        __block CMTime time_current = kCMTimeZero;
        return SGLockCondEXE11(self.lock, ^BOOL {
            return self->_current_frame && self->_nb_frames_fetch != 0;
        }, ^SGBlock {
            time_current = self->_current_frame.timeStamp;
            return nil;
        }, ^BOOL(SGBlock block) {
            CMTime time = kCMTimeZero;
            CMTime offset = kCMTimeZero;
            [self.clock preferredVideoTime:&time offset:&offset];
            double media_time_next = self.drawTimer.nextVSyncTimestamp;
            media_time_current = CACurrentMediaTime();
            * desire = CMTimeAdd(CMTimeAdd(time, offset), CMTimeMaximum(SGCMTimeMakeWithSeconds(media_time_next - media_time_current), kCMTimeZero));
            * current = time_current;
            * drop = YES;
            return YES;
        });
    }];
    SGLockEXE10(self.lock, ^SGBlock {
        SGCapacity * capacity = [[SGCapacity alloc] init];
        if (ret) {
            [self->_current_frame unlock];
            self->_current_frame = ret;
            self->_is_update_frame_draw = 1;
            self->_is_update_frame_output = 1;
            self->_nb_frames_fetch += 1;
            self->_media_time_timeout = media_time_current + CMTimeGetSeconds(SGCMTimeMultiply(ret.duration, self->_rate));
            [self.clock setVideoCurrentTime:self->_current_frame.timeStamp];
            capacity.duration = ret.duration;
        } else if (media_time_current < self->_media_time_timeout) {
            capacity.duration = SGCMTimeMakeWithSeconds(self->_media_time_timeout - media_time_current);
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
    SGLockEXE11(self.lock, ^SGBlock {
        SGBlock b1 = ^{}, b2 = ^{};
        if (self->_is_update_frame_output && self->_current_frame) {
            SGVideoFrame * frame = self->_current_frame;
            [frame lock];
            b1 = ^{
                if (self.frameOutput) {
                    self.frameOutput(frame);
                }
                [frame unlock];
            };
        }
        if ((self->_is_update_frame_draw || (self.displayMode == SGDisplayModeVR || self.displayMode == SGDisplayModeVRBox)) && self->_current_frame) {
            b2 = ^{
                [self addGLViewIfNeeded];
                if (self.glView.superview && self.glView.displaySize.width > 0) {
                    draw_ret = [self display];
                }
            };
        }
        return ^{
            b1(); b2();
        };
    }, ^BOOL(SGBlock block) {
        block();
        SGLockEXE10(self.lock, ^SGBlock {
            self->_is_update_frame_output = 0;
            if (draw_ret && self->_is_update_frame_draw) {
                self->_is_update_frame_draw = 0;
                self->_nb_frames_draw += 1;
            }
            SGBlock b1 = ^{};
            if (self->_state != SGRenderableStateRendering && self->_displayMode == SGDisplayModePlane && self->_nb_frames_draw) {
                b1 = ^{
                    self.drawTimer.paused = YES;
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
        if (!self.glView) {
            self.glView = [[SGGLView alloc] initWithFrame:self.view.bounds];
            self.glUploader = [[SGGLTextureUploader alloc] initWithGLContext:self.glView.context];
            self.glView.delegate = self;
        }
        if (self.glView.superview != self.view) {
            [self.view addSubview:self.glView];
        }
        SGGLSize layerSize = {CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)};
        if (layerSize.width != self.glView.displaySize.width ||
            layerSize.height != self.glView.displaySize.height) {
            self.glView.frame = self.view.bounds;
        }
    } else {
        [self.glView removeFromSuperview];
    }
}

- (void)removeGLViewIfNeeded
{
    [self.glView removeFromSuperview];
}

- (BOOL)display
{
#if SGPLATFORM_TARGET_OS_IPHONE
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        return [self.glView display];
    }
    return NO;
#else
    return [self.glView display];
#endif
}

- (BOOL)clear
{
#if SGPLATFORM_TARGET_OS_IPHONE
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        return [self.glView clear];
    }
    return NO;
#else
    return [self.glView clear];
#endif
}

- (BOOL)glView:(SGGLView *)glView display:(SGGLSize)size
{
    [self.lock lock];
    SGVideoFrame * frame = self->_current_frame;
    if (!frame || frame.width == 0 || frame.height == 0) {
        [self.lock unlock];
        return NO;
    }
    [frame lock];
    [self.lock unlock];
    SGGLSize textureSize = {frame.width, frame.height};
    SGDisplayMode displayMode = self.displayMode;
    id <SGGLModel> model = [self.modelPool modelWithType:SGDisplay2Model(displayMode)];
    id <SGGLProgram> program = [self.programPool programWithType:SGFormat2Program(frame.format, frame->_pixelBuffer)];
    if (!model || !program) {
        [frame unlock];
        return NO;
    }
    [program use];
    [program bindVariable];
    BOOL success = NO;
    if (frame->_pixelBuffer) {
        success = [self.glUploader uploadWithCVPixelBuffer:frame->_pixelBuffer];
    } else {
        success = [self.glUploader uploadWithType:SGFormat2Texture(frame.format, frame->_pixelBuffer) data:frame->_data size:textureSize];
    }
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
            if (![self.matrixMaker matrixWithAspect:aspect matrix1:&modelViewProjectionMatrix])
            {
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
            if (![self.matrixMaker matrixWithAspect:aspect matrix1:&modelViewProjectionMatrix1 matrix2:&modelViewProjectionMatrix2]) {
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

@end
