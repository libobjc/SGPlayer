//
//  SGVideoPlaybackOutput.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGVideoPlaybackOutput.h"
#import "SGFFDefinesMapping.h"
#import "SGGLDisplayLink.h"
#import "SGGLProgramPool.h"
#import "SGVideoAVFrame.h"
#import "SGVideoFFFrame.h"
#import "SGGLModelPool.h"
#import "SGGLViewport.h"
#import "SGGLTimer.h"
#import "SGGLView.h"
#import "SGVRMatrixMaker.h"
#import "SGMacro.h"

@interface SGVideoPlaybackOutput () <NSLocking, SGGLViewDelegate>

@property (nonatomic, assign) BOOL paused;
@property (nonatomic, assign) BOOL receivedFrame;
@property (nonatomic, assign) BOOL renderedFrame;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) SGObjectQueue * frameQueue;
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

@end

@implementation SGVideoPlaybackOutput

@synthesize delegate = _delegate;
@synthesize enable = _enable;
@synthesize key = _key;

- (SGMediaType)mediaType
{
    return SGMediaTypeVideo;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _enable = NO;
        _key = NO;
        self.rate = CMTimeMake(1, 1);
        self.frameQueue = [[SGObjectQueue alloc] init];
        self.frameQueue.shouldSortObjects = YES;
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

- (void)open
{
    if (!self.enable)
    {
        return;
    }
    self.displayLink = [SGGLDisplayLink displayLinkWithHandler:nil];
    SGWeakSelf
    NSTimeInterval timeInterval = CMTimeGetSeconds(self.displayInterval) / (NSTimeInterval)self.displayIncreasedCoefficient;
    self.renderTimer = [SGGLTimer timerWithTimeInterval:timeInterval handler:^{
        SGStrongSelf
        [self renderTimerHandler];
    }];
    self.displayLink.paused = NO;
    self.renderTimer.paused = NO;
}

- (void)pause
{
    if (!self.enable)
    {
        return;
    }
    self.paused = YES;
}

- (void)resume
{
    if (!self.enable)
    {
        return;
    }
    self.paused = NO;
}

- (void)close
{
    if (!self.enable)
    {
        return;
    }
    [self.frameQueue destroy];
    [self lock];
    [self.currentFrame unlock];
    self.currentFrame = nil;
    self.receivedFrame = NO;
    self.renderedFrame = NO;
    [self unlock];
}

- (void)putFrame:(__kindof SGFrame *)frame
{
    if (!self.enable)
    {
        return;
    }
    if (![frame isKindOfClass:[SGVideoFrame class]])
    {
        return;
    }
    SGVideoFrame * videoFrame = frame;
    if (self.key && !self.receivedFrame)
    {
        [self.timeSync updateKeyTime:videoFrame.timeStamp duration:kCMTimeZero rate:CMTimeMake(1, 1)];
    }
    self.receivedFrame = YES;
    [self.frameQueue putObjectSync:videoFrame];
    [self.delegate outputDidChangeCapacity:self];
}

- (void)flush
{
    if (!self.enable)
    {
        return;
    }
    [self lock];
    [self.currentFrame unlock];
    self.currentFrame = nil;
    self.receivedFrame = NO;
    self.renderedFrame = NO;
    [self unlock];
    [self.frameQueue flush];
    [self.delegate outputDidChangeCapacity:self];
}

#pragma mark - Setter & Getter

- (NSError *)error
{
    return nil;
}

- (BOOL)empty
{
    return self.count <= 0;
}

- (CMTime)duration
{
    if (self.frameQueue)
    {
        return self.frameQueue.duration;
    }
    return kCMTimeZero;
}

- (long long)size
{
    if (self.frameQueue)
    {
        return self.frameQueue.size;
    }
    return 0;
}

- (NSUInteger)count
{
    if (self.frameQueue)
    {
        return self.frameQueue.count;
    }
    return 0;
}

- (NSUInteger)maxCount
{
    return 3;
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
    BOOL needFetchFrame = !self.key || !self.paused || !self.renderedFrame;
    if (needFetchFrame)
    {
        SGWeakSelf
        frame = [self.frameQueue getObjectAsyncWithPTSHandler:^BOOL(CMTime * current, CMTime * expect) {
            SGStrongSelf
            if (!self.currentFrame)
            {
                return NO;
            }
            CMTime time = self.key ? self.timeSync.unlimitedTime : self.timeSync.time;
            NSTimeInterval nextVSyncInterval = MAX(self.displayLink.nextVSyncTimestamp - CACurrentMediaTime(), 0);
            * expect = CMTimeAdd(time, SGCMTimeMakeWithSeconds(nextVSyncInterval));
            * current = self.currentFrame.timeStamp;
            return YES;
        } drop:!self.key];
        if (frame)
        {
            NSAssert(self.currentFrame != frame, @"SGVideoPlaybackOutput : Frame can't equal to currentTime.");
            [self.currentFrame unlock];
            self.currentFrame = frame;
            self.renderedFrame = YES;
            callback = ^{
                if (self.key)
                {
                    [self.timeSync updateKeyTime:self.currentFrame.timeStamp duration:self.currentFrame.duration rate:self.rate];
                }
                if (self.displayCallback)
                {
                    self.displayCallback(frame);
                }
                [self.delegate outputDidChangeCapacity:self];
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
    if (!frame)
    {
        [self unlock];
        return;
    }
    [frame lock];
    [self unlock];
    callback();
    [self draw];
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
    id <SGGLModel> model = [self.modelPool modelWithType:SGDMDisplay2Model(displayMode)];
    id <SGGLProgram> program = [self.programPool programWithType:SGDMFormat2Program(frame.format)];
    if (!model || !program)
    {
        [frame unlock];
        return NO;
    }
    [program use];
    [program bindVariable];
    BOOL success = NO;
    if (frame.pixelBuffer)
    {
        success = [self.glUploader uploadWithCVPixelBuffer:frame.pixelBuffer];
    }
    else
    {
        success = [self.glUploader uploadWithType:SGDMFormat2Texture(frame.format) data:frame.data size:textureSize];
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
            [SGGLViewport updateWithLayerSize:size scale:glView.glScale textureSize:textureSize mode:SGDMScaling2Viewport(self.scalingMode)];
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
        self.coreLock = [[NSLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
