//
//  SGVideoPlaybackOutput.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGVideoPlaybackOutput.h"
#import "SGMacro.h"
#import "SGGLDisplayLink.h"
#import "SGGLTimer.h"
#import "SGGLView.h"
#import "SGGLRenderer.h"
#import "SGDefinesMapping.h"
#import "SGVideoAVFrame.h"
#import "SGVideoFFFrame.h"

@interface SGVideoPlaybackOutput () <SGGLViewDelegate, NSLocking>

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) SGObjectQueue * frameQueue;
@property (nonatomic, strong) SGVideoFrame * currentFrame;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, assign) BOOL timeSyncDidUpdate;
@property (nonatomic, assign) BOOL hasFrame;

@property (nonatomic, strong) SGGLDisplayLink * displayLink;
@property (nonatomic, strong) SGGLTimer * renderTimer;
@property (nonatomic, strong) SGGLView * glView;
@property (nonatomic, strong) SGGLRenderer * glRenderer;
@property (nonatomic, strong) SGGLTextureUploader * glTextureUploader;

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
        self.glRenderer = [[SGGLRenderer alloc] init];
        self.displayLink = [SGGLDisplayLink displayLinkWithHandler:nil];
        SGWeakSelf
        self.renderTimer = [SGGLTimer timerWithTimeInterval:1.0 / 60.0 handler:^{
            SGStrongSelf
            [self renderTimerHandler];
        }];
        self.displayLink.paused = YES;
        self.renderTimer.paused = YES;
    }
    return self;
}

- (void)dealloc
{
    [self.renderTimer invalidate];
    [self.displayLink invalidate];
    [self close];
}

#pragma mark - Interface

- (void)open
{
    if (!self.enable)
    {
        return;
    }
    self.frameQueue = [[SGObjectQueue alloc] init];
    self.frameQueue.shouldSortObjects = YES;
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
    self.timeSyncDidUpdate = NO;
    self.hasFrame = NO;
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
    if (self.key)
    {
        if ( !self.timeSyncDidUpdate && self.frameQueue.count == 0)
        {
            [self.timeSync updateKeyTime:videoFrame.timeStamp duration:kCMTimeZero rate:CMTimeMake(1, 1)];
        }
    }
    self.hasFrame = YES;
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
    self.timeSyncDidUpdate = NO;
    self.hasFrame = NO;
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

#pragma mark - Render

- (void)renderTimerHandler
{
    if (self.key)
    {
        if (self.timeSyncDidUpdate)
        {
            if (self.paused)
            {
                return;
            }
        }
        else
        {
            [self.timeSync refresh];
        }
    }
    [self lock];
    SGWeakSelf
    SGVideoFrame * render = [self.frameQueue getObjectAsyncWithPTSHandler:^BOOL(CMTime * current, CMTime * expect) {
        SGStrongSelf
        if (self.currentFrame)
        {
            CMTime time = self.key ? self.timeSync.unlimitedTime : self.timeSync.time;
            NSAssert(CMTIME_IS_VALID(time), @"Key time is invalid.");
            NSTimeInterval nextVSyncInterval = MAX(self.displayLink.nextVSyncTimestamp - CACurrentMediaTime(), 0);
            * expect = CMTimeAdd(time, SGCMTimeMakeWithSeconds(nextVSyncInterval));
            * current = self.currentFrame.timeStamp;
            return YES;
        }
        return NO;
    } drop:!self.key];
    if (!render)
    {
        [self unlock];
        return;
    }
    BOOL drawing = NO;
    if (render != self.currentFrame)
    {
        [self.currentFrame unlock];
        self.currentFrame = render;
        if (self.key)
        {
            self.timeSyncDidUpdate = YES;
            [self.timeSync updateKeyTime:self.currentFrame.timeStamp duration:self.currentFrame.duration rate:self.rate];
        }
        drawing = YES;
    }
    [self unlock];
    if (self.view)
    {
        if (drawing)
        {
            if (!self.glView)
            {
                self.glView = [[SGGLView alloc] initWithFrame:self.view.bounds];
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
            [self draw];
        }
    }
    else
    {
        [self.glView removeFromSuperview];
    }
    [self.delegate outputDidChangeCapacity:self];
}

#pragma mark - SGGLView

- (void)draw
{
#if SGPLATFORM_TARGET_OS_IPHONE
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
    {
        [self.glView display];
    }
#else
    [self.glView display];
#endif
}

- (BOOL)glView:(SGGLView *)glView draw:(SGGLSize)size
{
    [self lock];
    SGVideoFrame * frame = self.currentFrame;
    if (!frame)
    {
        [self unlock];
        return NO;
    }
    if (![frame isKindOfClass:[SGVideoFFFrame class]] &&
        ![frame isKindOfClass:[SGVideoAVFrame class]])
    {
        [self unlock];
        return NO;
    }
    if (frame.width == 0 || frame.height == 0)
    {
        [self unlock];
        return NO;
    }
    [frame lock];
    [self unlock];
    SGGLSize textureSize = {frame.width, frame.height};
    self.glRenderer.modelType = SGGLModelTypePlane;
    self.glRenderer.programType = SGFFDMProgram(frame.format);
    self.glRenderer.textureSize = textureSize;
    self.glRenderer.layerSize = size;
    self.glRenderer.scale = glView.glScale;
    if (![self.glRenderer bind])
    {
        [frame unlock];
        return NO;
    }
    if (!self.glTextureUploader)
    {
        self.glTextureUploader = [[SGGLTextureUploader alloc] initWithGLContext:self.glView.context];
    }
    BOOL success = NO;
    if ([frame isKindOfClass:[SGVideoFFFrame class]])
    {
        success = [self.glTextureUploader uploadWithType:SGFFDMTexture(frame.format) data:frame.data size:textureSize];
    }
    else if ([frame isKindOfClass:[SGVideoAVFrame class]])
    {
        success = [self.glTextureUploader uploadWithCVPixelBuffer:((SGVideoAVFrame *)frame).corePixelBuffer];
    }
    if (!success)
    {
        [self.glRenderer unbind];
        [frame unlock];
        return NO;
    }
    [self.glRenderer draw];
    [self.glRenderer unbind];
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
