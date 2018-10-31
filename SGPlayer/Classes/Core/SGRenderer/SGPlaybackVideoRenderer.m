//
//  SGPlaybackVideoRenderer.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPlaybackVideoRenderer.h"
#import "SGMapping.h"
#import "SGGLDisplayLink.h"
#import "SGGLProgramPool.h"
#import "SGGLModelPool.h"
#import "SGGLViewport.h"
#import "SGGLTimer.h"
#import "SGGLView.h"
#import "SGVRMatrixMaker.h"
#import "SGMacro.h"

@interface SGPlaybackVideoRenderer () <NSLocking, SGGLViewDelegate>

{
    SGRenderableState _state;
}

@property (nonatomic, strong) SGPlaybackClock * clock;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, assign) BOOL receivedFrame;
@property (nonatomic, strong) NSRecursiveLock * coreLock;
@property (nonatomic, strong) SGVideoFrame * currentFrame;
@property (nonatomic, strong) SGGLTimer * renderTimer;
@property (nonatomic, strong) SGGLDisplayLink * displayLink;
@property (nonatomic, strong) SGVRMatrixMaker * matrixMaker;
@property (nonatomic, strong) SGGLView * glView;
@property (nonatomic, strong) SGGLModelPool * modelPool;
@property (nonatomic, strong) SGGLProgramPool * programPool;
@property (nonatomic, strong) SGGLTextureUploader * glUploader;
@property (nonatomic, assign) NSUInteger displayIncreasedCoefficient;
@property (nonatomic, assign) NSUInteger displayCallbackCount;
@property (nonatomic, assign) NSUInteger displayNewFrameCount;

@end

@implementation SGPlaybackVideoRenderer

@synthesize object = _object;
@synthesize delegate = _delegate;
@synthesize key = _key;

- (instancetype)initWithClock:(SGPlaybackClock *)clock
{
    if (self = [super init])
    {
        self.clock = clock;
        _key = NO;
        self.rate = CMTimeMake(1, 1);
        self.programPool = [[SGGLProgramPool alloc] init];
        self.modelPool = [[SGGLModelPool alloc] init];
        self.matrixMaker = [[SGVRMatrixMaker alloc] init];
        self.displayInterval = CMTimeMake(1, 60);
        self.displayIncreasedCoefficient = 2;
    }
    return self;
}

- (void)dealloc
{
    [self.renderTimer invalidate];
    [self.displayLink invalidate];
    [self.glView removeFromSuperview];
    [self close];
}

#pragma mark - Interface

- (BOOL)open
{
    [self lock];
    if (self.state != SGRenderableStateNone)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGRenderableStatePaused];
    self.displayLink = [SGGLDisplayLink displayLinkWithHandler:nil];
    SGWeakSelf
    NSTimeInterval timeInterval = CMTimeGetSeconds(self.displayInterval) / (NSTimeInterval)self.displayIncreasedCoefficient;
    self.renderTimer = [SGGLTimer timerWithTimeInterval:timeInterval handler:^{
        SGStrongSelf
        [self renderTimerHandler];
    }];
    [self unlock];
    callback();
    self.displayLink.paused = NO;
    self.renderTimer.paused = NO;
    return YES;
}

- (BOOL)close
{
    [self lock];
    if (self.state == SGRenderableStateClosed)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGRenderableStateClosed];
    [self.currentFrame unlock];
    self.currentFrame = nil;
    self.receivedFrame = NO;
    self.displayNewFrameCount = 0;
    [self unlock];
    callback();
    return YES;
}

- (BOOL)pause
{
    [self lock];
    if (self.state != SGRenderableStateRendering)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGRenderableStatePaused];
    self.paused = YES;
    [self unlock];
    callback();
    return YES;
}

- (BOOL)resume
{
    [self lock];
    if (self.state != SGRenderableStatePaused)
    {
        [self unlock];
        return NO;
    }
    SGBasicBlock callback = [self setState:SGRenderableStateRendering];
    self.paused = NO;
    [self unlock];
    callback();
    return YES;
}

- (BOOL)putFrame:(__kindof SGFrame *)frame
{
    [self lock];
    if (self.state != SGRenderableStatePaused &&
        self.state != SGRenderableStateRendering)
    {
        [self unlock];
        return NO;
    }
    [self unlock];
    
    if (![frame isKindOfClass:[SGVideoFrame class]])
    {
        return NO;
    }
    SGVideoFrame * videoFrame = frame;
    if (self.key && !self.receivedFrame)
    {
        [self.clock updateKeyTime:videoFrame.timeStamp duration:kCMTimeZero rate:CMTimeMake(1, 1)];
    }
    self.receivedFrame = YES;
    return YES;
}

- (BOOL)flush
{
    [self lock];
    if (self.state != SGRenderableStatePaused &&
        self.state != SGRenderableStateRendering)
    {
        [self unlock];
        return NO;
    }
    [self.currentFrame unlock];
    self.currentFrame = nil;
    self.receivedFrame = NO;
    self.displayNewFrameCount = 0;
    [self unlock];
    return YES;
}

#pragma mark - Setter & Getter

- (SGBasicBlock)setState:(SGRenderableState)state
{
    if (_state != state)
    {
        _state = state;
        return ^{
            [self.delegate renderable:self didChangeState:state];
        };
    }
    return ^{};
}

- (SGRenderableState)state
{
    return _state;
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
    [self lock];
    SGVideoFrame * videoFrame = self.currentFrame;
    if (!videoFrame)
    {
        [self unlock];
        return nil;
    }
    [videoFrame lock];
    [self unlock];
    UIImage * image = [videoFrame image];
    [videoFrame unlock];
    return image;
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

#pragma mark - Internal

- (void)updateGLViewIfNeeded
{
    if (self.view)
    {
        if (!self.glView)
        {
            self.glView = [[SGGLView alloc] initWithFrame:self.view.bounds];
            self.glUploader = [[SGGLTextureUploader alloc] initWithGLContext:self.glView.context];
            self.glView.delegate = self;
        }
        if (self.glView.superview != self.view)
        {
            [self.view addSubview:self.glView];
        }
        SGGLSize layerSize = {CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)};
        if (layerSize.width != self.glView.displaySize.width ||
            layerSize.height != self.glView.displaySize.height)
        {
            self.glView.frame = self.view.bounds;
        }
    }
    else
    {
        [self.glView removeFromSuperview];
    }
}

#pragma mark - Render

- (void)renderTimerHandler
{
    [self lock];
    SGVideoFrame * frame = nil;
    SGBasicBlock callback = ^{};
    BOOL needFetchFrame = !self.key || !self.paused || (self.displayNewFrameCount == 0);
    if (needFetchFrame)
    {
        SGWeakSelf
        frame = [self.delegate renderableNeedMoreFrame:self ptsHandler:^BOOL(CMTime * current, CMTime * expect) {
            SGStrongSelf
            if (!self.currentFrame)
            {
                return NO;
            }
            CMTime time = self.key ? self.clock.unlimitedTime : self.clock.time;
            NSTimeInterval nextVSyncInterval = MAX(self.displayLink.nextVSyncTimestamp - CACurrentMediaTime(), 0);
            * expect = CMTimeAdd(time, SGCMTimeMakeWithSeconds(nextVSyncInterval));
            * current = self.currentFrame.timeStamp;
            return YES;
        } drop:!self.key];
        if (frame && self.discardFilter)
        {
            CMSampleTimingInfo timingInfo = {kCMTimeZero};
            timingInfo.presentationTimeStamp = frame.timeStamp;
            timingInfo.decodeTimeStamp = frame.decodeTimeStamp;
            timingInfo.duration = frame.duration;
            if (self.discardFilter(timingInfo, self.displayNewFrameCount))
            {
                [frame unlock];
                frame = nil;
                callback = ^{
//                    [self callbackForCapacity];
                };
            }
        }
        if (frame)
        {
            NSAssert(self.currentFrame != frame, @"SGPlaybackVideoRenderer : Frame can't equal to currentTime.");
            self.displayNewFrameCount += 1;
            [self.currentFrame unlock];
            self.currentFrame = frame;
            callback = ^{
                if (self.key)
                {
                    [self.clock updateKeyTime:self.currentFrame.timeStamp duration:self.currentFrame.duration rate:self.rate];
                }
                if (self.renderCallback)
                {
                    self.renderCallback(frame);
                }
//                [self callbackForCapacity];
            };
        }
    }
    [self updateGLViewIfNeeded];
    self.displayCallbackCount += 1;
    if (!frame)
    {
        BOOL delivery = (self.displayCallbackCount % self.displayIncreasedCoefficient) == 0;
        BOOL viewReady = (self.glView.superview && !self.glView.rendered);
        BOOL isVR = self.displayMode == SGDisplayModeVR || self.displayMode == SGDisplayModeVRBox;
        BOOL VRReady = (isVR && self.matrixMaker.ready);
        BOOL needRedraw = delivery && (viewReady || VRReady);
        if (needRedraw)
        {
            frame = self.currentFrame;
        }
    }
    [frame lock];
    [self unlock];
    callback();
    if (frame)
    {
        [self draw];
    }
    [frame unlock];
}

#pragma mark - SGGLView

- (BOOL)draw
{
#if SGPLATFORM_TARGET_OS_IPHONE
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
    {
        return [self.glView display];
    }
    return NO;
#else
    return [self.glView display];
#endif
}

- (BOOL)glView:(SGGLView *)glView draw:(SGGLSize)size
{
    [self lock];
    SGVideoFrame * frame = self.currentFrame;
    if (!frame || frame.width == 0 || frame.height == 0)
    {
        [self unlock];
        return NO;
    }
    [frame lock];
    [self unlock];
    SGGLSize textureSize = {frame.width, frame.height};
    SGDisplayMode displayMode = self.displayMode;
    id <SGGLModel> model = [self.modelPool modelWithType:SGDisplay2Model(displayMode)];
    id <SGGLProgram> program = [self.programPool programWithType:SGFormat2Program(frame.format, frame->_pixelBuffer)];
    if (!model || !program)
    {
        [frame unlock];
        return NO;
    }
    [program use];
    [program bindVariable];
    BOOL success = NO;
    if (frame->_pixelBuffer)
    {
        success = [self.glUploader uploadWithCVPixelBuffer:frame->_pixelBuffer];
    }
    else
    {
        success = [self.glUploader uploadWithType:SGFormat2Texture(frame.format, frame->_pixelBuffer) data:frame->_data size:textureSize];
    }
    if (!success)
    {
        [model unbind];
        [program unuse];
        [frame unlock];
        return NO;
    }
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [model bindPosition_location:program.position_location
      textureCoordinate_location:program.textureCoordinate_location];
    switch (displayMode)
    {
        case SGDisplayModePlane:
        {
            [program updateModelViewProjectionMatrix:GLKMatrix4Identity];
            [SGGLViewport updateWithLayerSize:size scale:glView.glScale textureSize:textureSize mode:SGScaling2Viewport(self.scalingMode)];
            [model draw];
        }
            break;
        case SGDisplayModeVR:
        {
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
        case SGDisplayModeVRBox:
        {
            double aspect = (float)size.width / (float)size.height / 2;
            GLKMatrix4 modelViewProjectionMatrix1 = GLKMatrix4Identity;
            GLKMatrix4 modelViewProjectionMatrix2 = GLKMatrix4Identity;
            if (![self.matrixMaker matrixWithAspect:aspect matrix1:&modelViewProjectionMatrix1 matrix2:&modelViewProjectionMatrix2])
            {
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

#pragma mark - NSLocking

- (void)lock
{
    if (!self.coreLock)
    {
        self.coreLock = [[NSRecursiveLock alloc] init];
    }
//    [self.coreLock lock];
}

- (void)unlock
{
//    [self.coreLock unlock];
}

@end
