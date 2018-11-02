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
    float64_t _invalid_media_time;
    __strong SGCapacity * _capacity;
    __strong SGVideoFrame * _fetched_frame;
    __strong SGVideoFrame * _drawed_frame;
}

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) SGClock * clock;
@property (nonatomic, assign) CMTime rate;
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
@synthesize key = _key;

- (instancetype)initWithClock:(SGClock *)clock
{
    if (self = [super init]) {
        self.clock = clock;
        self.rate = CMTimeMake(1, 1);
        self.scalingMode = SGScalingModeResizeAspect;
        self.displayMode = SGDisplayModePlane;
        self.displayInterval = CMTimeMake(1, 60);
        self.modelPool = [[SGGLModelPool alloc] init];
        self.programPool = [[SGGLProgramPool alloc] init];
        self.matrixMaker = [[SGVRMatrixMaker alloc] init];
    }
    return self;
}

- (void)dealloc
{
    
    [self.fetchTimer invalidate];
    [self.drawTimer invalidate];
    if ([NSThread isMainThread]) {
        [self.glView removeFromSuperview];
    } else {
        SGGLView * glView = self.glView;
        self.glView = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [glView removeFromSuperview];
        });
    }
    [self close];
    SGLockEXE00(self.lock, ^{
        [self->_drawed_frame unlock];
        self->_drawed_frame = nil;
    });
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

- (SGVRViewport *)viewport
{
    return self.matrixMaker.viewport;
}

- (UIImage *)originalImage
{
    __block UIImage * ret = nil;
    SGLockCondEXE11(self.lock, ^BOOL {
        return self->_drawed_frame;
    }, ^SGBlock{
        SGVideoFrame * frame = self->_drawed_frame;
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
        [self->_fetched_frame unlock];
        self->_fetched_frame = nil;
        self->_invalid_media_time = 0;
        return [self setState:SGRenderableStateNone];
    }, ^BOOL(SGBlock block) {
        [self.fetchTimer invalidate];
        [self.drawTimer invalidate];
        self.fetchTimer = nil;
        self.drawTimer = nil;
        block();
        return YES;
    });
}

- (BOOL)pause
{
    return SGLockCondEXE10(self.lock, ^BOOL {
        return self->_state == SGRenderableStateRendering;
    }, ^SGBlock {
        return [self setState:SGRenderableStatePaused];
    });
}

- (BOOL)resume
{
    return SGLockCondEXE10(self.lock, ^BOOL {
        return self->_state == SGRenderableStatePaused;
    }, ^SGBlock {
        return [self setState:SGRenderableStateRendering];
    });
}

- (BOOL)flush
{
    SGLockCondEXE00(self.lock, ^BOOL {
        return self->_state == SGRenderableStatePaused || self->_state == SGRenderableStateRendering;
    }, ^ {
        [self->_fetched_frame unlock];
        self->_fetched_frame = nil;
        self->_invalid_media_time = 0;
    });
    return YES;
}

#pragma mark - Internal

- (void)updateGLViewIfNeeded
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

#pragma mark - Render

- (void)fetchTimerHandler
{
    __block float64_t next_media_time = self.drawTimer.nextVSyncTimestamp;
    __block float64_t current_media_time = CACurrentMediaTime();
    SGWeakify(self)
    SGVideoFrame * ret = [self.delegate renderable:self fetchFrame:^BOOL(CMTime * current, CMTime * desire, BOOL * drop) {
        SGStrongify(self)
        __block CMTime t = kCMTimeZero;
        return SGLockCondEXE11(self.lock, ^BOOL {
            return self->_fetched_frame;
        }, ^SGBlock {
            t = self->_fetched_frame.timeStamp;
            return nil;
        }, ^BOOL(SGBlock block) {
            CMTime time = self.clock.time;
            next_media_time = self.drawTimer.nextVSyncTimestamp;
            current_media_time = CACurrentMediaTime();
            * desire = CMTimeAdd(time, SGCMTimeMakeWithSeconds(next_media_time - current_media_time));
            * current = t;
            * drop = YES;
            return YES;
        });
    }];
    SGLockEXE10(self.lock, ^SGBlock {
        SGCapacity * capacity = [[SGCapacity alloc] init];
        if (ret) {
            [self->_fetched_frame unlock];
            self->_fetched_frame = ret;
            self->_invalid_media_time = next_media_time + CMTimeGetSeconds(ret.duration);
            capacity.duration = ret.duration;
        } else if (current_media_time >= self->_invalid_media_time) {
            [self->_fetched_frame unlock];
            self->_fetched_frame = nil;
            self->_invalid_media_time = 0;
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
    [self updateGLViewIfNeeded];
}

- (void)drawTimerHandler
{
    BOOL ret = SGLockCondEXE10(self.lock, ^BOOL{
        return self->_fetched_frame;
    }, ^SGBlock {
        [self->_fetched_frame lock];
        [self->_drawed_frame unlock];
        self->_drawed_frame = self->_fetched_frame;
        return nil;
    });
    if (ret && self.glView.superview) {
        [self draw];
    }
}

#pragma mark - SGGLView

- (BOOL)draw
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

- (BOOL)glView:(SGGLView *)glView draw:(SGGLSize)size
{
    [self.lock lock];
    SGVideoFrame * frame = self->_drawed_frame;
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

@end
