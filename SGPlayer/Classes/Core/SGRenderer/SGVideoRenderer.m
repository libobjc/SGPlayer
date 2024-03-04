//
//  SGVideoRenderer.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGVideoRenderer.h"
#import "SGRenderer+Internal.h"
#import "SGVRProjection.h"
#import "SGRenderTimer.h"
#import "SGOptions.h"
#import "SGMapping.h"
#import "SGMetal.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGVideoRenderer () <MTKViewDelegate>

{
    struct {
        SGRenderableState state;
        BOOL hasNewFrame;
        NSUInteger framesFetched;
        NSUInteger framesDisplayed;
        NSTimeInterval currentFrameEndTime;
        NSTimeInterval currentFrameBeginTime;
    } _flags;
    SGCapacity _capacity;
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) SGClock *clock;
@property (nonatomic, strong, readonly) SGRenderTimer *fetchTimer;
@property (nonatomic, strong, readonly) SGVideoFrame *currentFrame;
@property (nonatomic, strong, readonly) SGVRProjection *matrixMaker;

@property (nonatomic, strong, readonly) MTKView *metalView;
@property (nonatomic, strong, readonly) SGMetalModel *planeModel;
@property (nonatomic, strong, readonly) SGMetalModel *sphereModel;
@property (nonatomic, strong, readonly) SGMetalRenderer *renderer;
@property (nonatomic, strong, readonly) SGMetalProjection *projection1;
@property (nonatomic, strong, readonly) SGMetalProjection *projection2;
@property (nonatomic, strong, readonly) SGMetalRenderPipeline *pipeline;
@property (nonatomic, strong, readonly) SGMetalTextureLoader *textureLoader;
@property (nonatomic, strong, readonly) SGMetalRenderPipelinePool *pipelinePool;

@end

@implementation SGVideoRenderer

@synthesize rate = _rate;
@synthesize delegate = _delegate;

+ (NSArray<NSNumber *> *)supportedPixelFormats
{
    return @[
        @(AV_PIX_FMT_BGRA),
        @(AV_PIX_FMT_NV12),
        @(AV_PIX_FMT_YUV420P),
    ];
}

+ (BOOL)isSupportedPixelFormat:(int)format
{
    for (NSNumber *obj in [self supportedPixelFormats]) {
        if (format == obj.intValue) {
            return YES;
        }
    }
    return NO;
}

- (instancetype)init
{
    NSAssert(NO, @"Invalid Function.");
    return nil;
}

- (instancetype)initWithClock:(SGClock *)clock
{
    if (self = [super init]) {
        self->_clock = clock;
        self->_rate = 1.0;
        self->_lock = [[NSLock alloc] init];
        self->_capacity = SGCapacityCreate();
        self->_preferredFramesPerSecond = 30;
        self->_displayMode = SGDisplayModePlane;
        self->_scalingMode = SGScalingModeResizeAspect;
        self->_matrixMaker = [[SGVRProjection alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self performSelectorOnMainThread:@selector(destoryDrawingLoop)
                           withObject:nil
                        waitUntilDone:YES];
    [self->_currentFrame unlock];
    self->_currentFrame = nil;
}

#pragma mark - Setter & Getter

- (SGBlock)setState:(SGRenderableState)state
{
    if (self->_flags.state == state) {
        return ^{};
    }
    self->_flags.state = state;
    return ^{
        [self->_delegate renderable:self didChangeState:state];
    };
}

- (SGRenderableState)state
{
    __block SGRenderableState ret = SGRenderableStateNone;
    SGLockEXE00(self->_lock, ^{
        ret = self->_flags.state;
    });
    return ret;
}

- (SGCapacity)capacity
{
    __block SGCapacity ret;
    SGLockEXE00(self->_lock, ^{
        ret = self->_capacity;
    });
    return ret;
}

- (void)setRate:(Float64)rate
{
    SGLockEXE00(self->_lock, ^{
        self->_rate = rate;
    });
}

- (Float64)rate
{
    __block Float64 ret = 1.0;
    SGLockEXE00(self->_lock, ^{
        ret = self->_rate;
    });
    return ret;
}

- (SGVRViewport *)viewport
{
    return self->_matrixMaker.viewport;
}

- (SGPLFImage *)currentImage
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

#pragma mark - Interface

- (BOOL)open
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == SGRenderableStateNone;
    }, ^SGBlock {
        return [self setState:SGRenderableStatePaused];
    }, ^BOOL(SGBlock block) {
        block();
        [self performSelectorOnMainThread:@selector(setupDrawingLoop)
                               withObject:nil
                            waitUntilDone:YES];
        return YES;
    });
}

- (BOOL)close
{
    return SGLockEXE11(self->_lock, ^SGBlock {
        SGBlock b1 = [self setState:SGRenderableStateNone];
        [self->_currentFrame unlock];
        self->_currentFrame = nil;
        self->_flags.hasNewFrame = NO;
        self->_flags.framesFetched = 0;
        self->_flags.framesDisplayed = 0;
        self->_flags.currentFrameEndTime = 0;
        self->_flags.currentFrameBeginTime = 0;
        self->_capacity = SGCapacityCreate();
        return ^{b1();};
    }, ^BOOL(SGBlock block) {
        [self performSelectorOnMainThread:@selector(destoryDrawingLoop)
                               withObject:nil
                            waitUntilDone:YES];
        block();
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return
        self->_flags.state == SGRenderableStateRendering ||
        self->_flags.state == SGRenderableStateFinished;
    }, ^SGBlock {
        return [self setState:SGRenderableStatePaused];
    }, ^BOOL(SGBlock block) {
        self->_metalView.paused = NO;
        self->_fetchTimer.paused = NO;
        return YES;
    });
}

- (BOOL)resume
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return
        self->_flags.state == SGRenderableStatePaused ||
        self->_flags.state == SGRenderableStateFinished;
    }, ^SGBlock {
        return [self setState:SGRenderableStateRendering];
    }, ^BOOL(SGBlock block) {
        self->_metalView.paused = NO;
        self->_fetchTimer.paused = NO;
        return YES;
    });
}

- (BOOL)flush
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return
        self->_flags.state == SGRenderableStatePaused ||
        self->_flags.state == SGRenderableStateRendering ||
        self->_flags.state == SGRenderableStateFinished;
    }, ^SGBlock {
        [self->_currentFrame unlock];
        self->_currentFrame = nil;
        self->_flags.hasNewFrame = NO;
        self->_flags.framesFetched = 0;
        self->_flags.framesDisplayed = 0;
        self->_flags.currentFrameEndTime = 0;
        self->_flags.currentFrameBeginTime = 0;
        return nil;
    }, ^BOOL(SGBlock block) {
        self->_metalView.paused = NO;
        self->_fetchTimer.paused = NO;
        return YES;
    });
}

- (BOOL)finish
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return
        self->_flags.state == SGRenderableStateRendering ||
        self->_flags.state == SGRenderableStatePaused;
    }, ^SGBlock {
        return [self setState:SGRenderableStateFinished];
    }, ^BOOL(SGBlock block) {
        self->_metalView.paused = NO;
        self->_fetchTimer.paused = NO;
        return YES;
    });
}

#pragma mark - Fecth

- (void)fetchTimerHandler
{
    BOOL shouldFetch = NO;
    BOOL shouldPause = NO;
    [self->_lock lock];
    if (self->_flags.state == SGRenderableStateRendering ||
        (self->_flags.state == SGRenderableStatePaused &&
         self->_flags.framesFetched == 0)) {
        shouldFetch = YES;
    } else if (self->_flags.state != SGRenderableStateRendering) {
        shouldPause = YES;
    }
    [self->_lock unlock];
    if (shouldPause) {
        self->_fetchTimer.paused = YES;
    }
    if (!shouldFetch) {
        return;
    }
    __block NSUInteger framesFetched = 0;
    __block NSTimeInterval currentMediaTime = CACurrentMediaTime();
    SGWeakify(self)
    SGVideoFrame *newFrame = [self->_delegate renderable:self fetchFrame:^BOOL(CMTime *desire, BOOL *drop) {
        SGStrongify(self)
        return SGLockCondEXE10(self->_lock, ^BOOL {
            framesFetched = self->_flags.framesFetched;
            return self->_currentFrame && framesFetched != 0;
        }, ^SGBlock {
            return ^{
                currentMediaTime = CACurrentMediaTime();
                *desire = self->_clock.currentTime;
                *drop = YES;
            };
        });
    }];
    SGLockCondEXE10(self->_lock, ^BOOL {
        return !newFrame || framesFetched == self->_flags.framesFetched;
    }, ^SGBlock {
        SGBlock b1 = ^{}, b2 = ^{}, b3 = ^{};
        SGCapacity capacity = SGCapacityCreate();
        if (newFrame) {
            [newFrame lock];
            CMTime time = newFrame.timeStamp;
            CMTime duration = CMTimeMultiplyByFloat64(newFrame.duration, self->_rate);
            capacity.duration = duration;
            [self->_currentFrame unlock];
            self->_currentFrame = newFrame;
            self->_flags.hasNewFrame = YES;
            self->_flags.framesFetched += 1;
            self->_flags.currentFrameBeginTime = currentMediaTime;
            self->_flags.currentFrameEndTime = currentMediaTime + CMTimeGetSeconds(duration);
            if (self->_frameOutput) {
                [newFrame lock];
                b1 = ^{
                    self->_frameOutput(newFrame);
                    [newFrame unlock];
                };
            }
            b2 = ^{
                [self->_clock setVideoTime:time];
            };
        } else if (currentMediaTime < self->_flags.currentFrameEndTime) {
            CMTime time = self->_currentFrame.timeStamp;
            time = CMTimeAdd(time, SGCMTimeMakeWithSeconds(currentMediaTime - self->_flags.currentFrameBeginTime));
            capacity.duration = SGCMTimeMakeWithSeconds(self->_flags.currentFrameEndTime - currentMediaTime);
            b2 = ^{
                [self->_clock setVideoTime:time];
            };
        }
        if (!SGCapacityIsEqual(self->_capacity, capacity)) {
            self->_capacity = capacity;
            b3 = ^{
                [self->_delegate renderable:self didChangeCapacity:capacity];
            };
        }
        return ^{b1(); b2(); b3();};
    });
    [newFrame unlock];
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView *)view
{
    if (!view.superview ||
        (view.frame.size.width <= 1 &&
         view.frame.size.height <= 1)) {
        return;
    }
    [self->_lock lock];
    SGVideoFrame *frame = self->_currentFrame;
    SGRational presentationSize = frame.descriptor.presentationSize;
    if (!frame ||
        presentationSize.num == 0 ||
        presentationSize.den == 0) {
        [self->_lock unlock];
        return;
    }
    BOOL shouldDraw = NO;
    if (self->_flags.hasNewFrame ||
        self->_flags.framesDisplayed == 0 ||
        (self->_displayMode == SGDisplayModeVR ||
         self->_displayMode == SGDisplayModeVRBox)) {
            shouldDraw = YES;
    }
    if (!shouldDraw) {
        BOOL shouldPause = self->_flags.state != SGRenderableStateRendering;
        [self->_lock unlock];
        if (shouldPause) {
            self->_metalView.paused = YES;
        }
        return;
    }
    NSUInteger framesFetched = self->_flags.framesFetched;
    [frame lock];
    [self->_lock unlock];
    SGDisplayMode displayMode = self->_displayMode;
    SGMetalModel *model = displayMode == SGDisplayModePlane ? self->_planeModel : self->_sphereModel;
    SGMetalRenderPipeline *pipeline = [self->_pipelinePool pipelineWithCVPixelFormat:frame.descriptor.cv_format];
    if (!model || !pipeline) {
        [frame unlock];
        return;
    }
    GLKMatrix4 baseMatrix = GLKMatrix4Identity;
    NSInteger rotate = [frame.metadata[@"rotate"] integerValue];
    if (rotate && (rotate % 90) == 0) {
        float radians = GLKMathDegreesToRadians(-rotate);
        baseMatrix = GLKMatrix4RotateZ(baseMatrix, radians);
        SGRational size = {
            presentationSize.num * ABS(cos(radians)) + presentationSize.den * ABS(sin(radians)),
            presentationSize.num * ABS(sin(radians)) + presentationSize.den * ABS(cos(radians)),
        };
        presentationSize = size;
    }
    NSArray<id<MTLTexture>> *textures = nil;
    if (frame.pixelBuffer) {
        textures = [self->_textureLoader texturesWithCVPixelBuffer:frame.pixelBuffer];
    } else {
        textures = [self->_textureLoader texturesWithCVPixelFormat:frame.descriptor.cv_format
                                                             width:frame.descriptor.width
                                                            height:frame.descriptor.height
                                                             bytes:(void **)frame.data
                                                       bytesPerRow:frame.linesize];
    }
    [frame unlock];
    if (!textures.count) {
        return;
    }
    MTLViewport viewports[2] = {};
    NSArray<SGMetalProjection *> *projections = nil;
    CGSize drawableSize = [self->_metalView drawableSize];
    id <CAMetalDrawable> drawable = [self->_metalView currentDrawable];
    if (drawableSize.width == 0 || drawableSize.height == 0) {
        return;
    }
    MTLSize textureSize = MTLSizeMake(presentationSize.num, presentationSize.den, 0);
    MTLSize layerSize = MTLSizeMake(drawable.texture.width, drawable.texture.height, 0);
    switch (displayMode) {
        case SGDisplayModePlane: {
            self->_projection1.matrix = baseMatrix;
            projections = @[self->_projection1];
            viewports[0] = [SGMetalViewport viewportWithLayerSize:layerSize textureSize:textureSize mode:SGScaling2Viewport(self->_scalingMode)];
        }
            break;
        case SGDisplayModeVR: {
            GLKMatrix4 matrix = GLKMatrix4Identity;
            Float64 aspect = (Float64)drawable.texture.width / drawable.texture.height;
            if (![self->_matrixMaker matrixWithAspect:aspect matrix1:&matrix]) {
                break;
            }
            self->_projection1.matrix = GLKMatrix4Multiply(baseMatrix, matrix);
            projections = @[self->_projection1];
            viewports[0] = [SGMetalViewport viewportWithLayerSize:layerSize];
        }
            break;
        case SGDisplayModeVRBox: {
            GLKMatrix4 matrix1 = GLKMatrix4Identity;
            GLKMatrix4 matrix2 = GLKMatrix4Identity;
            Float64 aspect = (Float64)drawable.texture.width / drawable.texture.height / 2.0;
            if (![self->_matrixMaker matrixWithAspect:aspect matrix1:&matrix1 matrix2:&matrix2]) {
                break;
            }
            self->_projection1.matrix = GLKMatrix4Multiply(baseMatrix, matrix1);
            self->_projection2.matrix = GLKMatrix4Multiply(baseMatrix, matrix2);
            projections = @[self->_projection1, self->_projection2];
            viewports[0] = [SGMetalViewport viewportWithLayerSizeForLeft:layerSize];
            viewports[1] = [SGMetalViewport viewportWithLayerSizeForRight:layerSize];
        }
            break;
    }
    if (projections.count) {
        id<MTLCommandBuffer> commandBuffer = [self.renderer drawModel:model
                                                            viewports:viewports
                                                             pipeline:pipeline
                                                          projections:projections
                                                        inputTextures:textures
                                                        outputTexture:drawable.texture];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
        [self->_lock lock];
        if (self->_flags.framesFetched == framesFetched) {
            self->_flags.framesDisplayed += 1;
            self->_flags.hasNewFrame = NO;
        }
        [self->_lock unlock];
    }
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    SGLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state == SGRenderableStateRendering ||
        self->_flags.state == SGRenderableStatePaused ||
        self->_flags.state == SGRenderableStateFinished;
    }, ^SGBlock{
        self->_flags.framesDisplayed = 0;
        return ^{
            self->_metalView.paused = NO;
            self->_fetchTimer.paused = NO;
        };
    });
}

#pragma mark - Metal

- (void)setupDrawingLoop
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    self->_renderer = [[SGMetalRenderer alloc] initWithDevice:device];
    self->_planeModel = [[SGMetalPlaneModel alloc] initWithDevice:device];
    self->_projection1 = [[SGMetalProjection alloc] initWithDevice:device];
    self->_projection2 = [[SGMetalProjection alloc] initWithDevice:device];
    self->_sphereModel = [[SGMetalSphereModel alloc] initWithDevice:device];
    self->_textureLoader = [[SGMetalTextureLoader alloc] initWithDevice:device];
    self->_pipelinePool = [[SGMetalRenderPipelinePool alloc] initWithDevice:device];
    self->_metalView = [[MTKView alloc] initWithFrame:CGRectZero device:device];
    self->_metalView.preferredFramesPerSecond = self->_preferredFramesPerSecond;
    self->_metalView.translatesAutoresizingMaskIntoConstraints = NO;
    self->_metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self->_metalView.delegate = self;
    SGWeakify(self)
    self->_fetchTimer = [[SGRenderTimer alloc] initWithHandler:^{
        SGStrongify(self)
        [self fetchTimerHandler];
    }];
    [self updateMetalView];
    [self updateTimeInterval];
}

- (void)destoryDrawingLoop
{
    [self->_fetchTimer stop];
    self->_fetchTimer = nil;
    [self->_metalView removeFromSuperview];
    self->_metalView = nil;
    self->_renderer = nil;
    self->_planeModel = nil;
    self->_sphereModel = nil;
    self->_projection1 = nil;
    self->_projection2 = nil;
    self->_pipelinePool = nil;
    self->_textureLoader = nil;
}

- (void)setView:(SGPLFView *)view
{
    if (self->_view != view) {
        self->_view = view;
        [self updateMetalView];
        [self updateTimeInterval];
    }
}

- (void)setPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond
{
    if (self->_preferredFramesPerSecond != preferredFramesPerSecond) {
        self->_preferredFramesPerSecond = preferredFramesPerSecond;
        [self updateTimeInterval];
    }
}

- (void)setDisplayMode:(SGDisplayMode)displayMode
{
    if (self->_displayMode != displayMode) {
        self->_displayMode = displayMode;
        SGLockCondEXE10(self->_lock, ^BOOL {
            return
            self->_displayMode != SGDisplayModePlane &&
            (self->_flags.state == SGRenderableStateRendering ||
             self->_flags.state == SGRenderableStatePaused ||
             self->_flags.state == SGRenderableStateFinished);
        }, ^SGBlock{
            return ^{
                self->_metalView.paused = NO;
                self->_fetchTimer.paused = NO;
            };
        });
    }
}

- (void)updateMetalView
{
    if (self->_view &&
        self->_metalView &&
        self->_metalView.superview != self->_view) {
        SGPLFViewInsertSubview(self->_view, self->_metalView, 0);
        NSLayoutConstraint *c1 = [NSLayoutConstraint constraintWithItem:self->_metalView
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self->_view
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:0.0];
        NSLayoutConstraint *c2 = [NSLayoutConstraint constraintWithItem:self->_metalView
                                                              attribute:NSLayoutAttributeLeft
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self->_view
                                                              attribute:NSLayoutAttributeLeft
                                                             multiplier:1.0
                                                               constant:0.0];
        NSLayoutConstraint *c3 = [NSLayoutConstraint constraintWithItem:self->_metalView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self->_view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0.0];
        NSLayoutConstraint *c4 = [NSLayoutConstraint constraintWithItem:self->_metalView
                                                              attribute:NSLayoutAttributeRight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self->_view
                                                              attribute:NSLayoutAttributeRight
                                                             multiplier:1.0
                                                               constant:0.0];
        [self->_view addConstraints:@[c1, c2, c3, c4]];
    } else {
        [self->_metalView removeFromSuperview];
    }
}

- (void)updateTimeInterval
{
    self->_fetchTimer.timeInterval = 0.5 / self->_preferredFramesPerSecond;
    if (self->_view &&
        self->_view == self->_metalView.superview) {
        self->_metalView.preferredFramesPerSecond = self->_preferredFramesPerSecond;
    } else {
        self->_metalView.preferredFramesPerSecond = 1;
    }
}

@end
