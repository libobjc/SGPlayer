//
//  SGFFVideoOutput.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoOutput.h"
#import "SGPlayerMacro.h"
#import "SGGLDisplayLink.h"
#import "SGGLTimer.h"
#import "SGGLView.h"
#import "SGGLViewport.h"
#import "SGGLModelPool.h"
#import "SGGLProgramPool.h"
#import "SGGLTextureUploader.h"
#import "SGFFDefineMap.h"
#import "SGFFVideoAVFrame.h"
#import "SGFFVideoFFFrame.h"

@interface SGFFVideoOutput () <SGGLViewDelegate>

@property (nonatomic, strong) SGFFObjectQueue * frameQueue;
@property (nonatomic, strong) SGFFVideoFrame * currentFrame;

@property (nonatomic, strong) SGGLDisplayLink * displayLink;
@property (nonatomic, strong) SGGLTimer * renderTimer;
@property (nonatomic, strong) SGGLView * glView;
@property (nonatomic, strong) SGGLModelPool * modelPool;
@property (nonatomic, strong) SGGLProgramPool * programPool;
@property (nonatomic, strong) SGGLTextureUploader * textureUploader;

@end

@implementation SGFFVideoOutput

@synthesize delegate = _delegate;
@synthesize timeSynchronizer = _timeSynchronizer;

- (SGMediaType)mediaType
{
    return SGMediaTypeVideo;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.frameQueue = [[SGFFObjectQueue alloc] init];
        self.frameQueue.shouldSortObjects = YES;
        self.glView = [[SGGLView alloc] initWithFrame:CGRectZero];
        self.glView.delegate = self;
        self.displayLink = [SGGLDisplayLink displayLinkWithHandler:nil];
        SGWeakSelf
        self.renderTimer = [SGGLTimer timerWithTimeInterval:1.0 / 60.0 handler:^{
            SGStrongSelf
            [strongSelf renderTimerHandler];
        }];
        self.renderTimer.fireDate = [NSDate distantPast];
    }
    return self;
}

- (void)dealloc
{
    [self.renderTimer invalidate];
    [self.displayLink invalidate];
    [self stop];
}

#pragma mark - Interface

- (void)start
{
    
}

- (void)stop
{
    [self.frameQueue destroy];
    [self.currentFrame unlock];
    self.currentFrame = nil;
}

- (void)putFrame:(__kindof SGFFFrame *)frame
{
    if (![frame isKindOfClass:[SGFFVideoFrame class]])
    {
        return;
    }
    SGFFVideoFrame * videoFrame = frame;
    
    [self.frameQueue putObjectSync:videoFrame];
    [self.delegate outputDidChangeCapacity:self];
}

- (void)flush
{
    [self.currentFrame unlock];
    self.currentFrame = nil;
    [self.frameQueue flush];
    [self.delegate outputDidChangeCapacity:self];
}

#pragma mark - Setter/Getter

- (NSUInteger)count
{
    return self.frameQueue.count;
}

- (CMTime)duration
{
    return self.frameQueue.duration;
}

- (long long)size
{
    return self.frameQueue.size;
}

- (SGPLFView *)displayView
{
    return self.glView;
}

#pragma mark - Render

- (void)renderTimerHandler
{
    SGWeakSelf
    SGFFVideoFrame * render = [self.frameQueue getObjectAsyncWithPositionHandler:^BOOL(CMTime * current, CMTime * expect) {
        SGStrongSelf
        if (strongSelf.currentFrame)
        {
            CMTime keyTime = strongSelf.timeSynchronizer.position;
            NSAssert(CMTIME_IS_VALID(keyTime), @"Key time is invalid.");
            NSTimeInterval nextVSyncInterval = MAX(strongSelf.displayLink.nextVSyncTimestamp - CACurrentMediaTime(), 0);
            * expect = CMTimeAdd(keyTime, SGFFTimeMakeWithSeconds(nextVSyncInterval));
            * current = strongSelf.currentFrame.position;
            return YES;
        }
        return NO;
    } drop:YES];
    if (render && render != self.currentFrame)
    {
        [self.delegate outputDidChangeCapacity:self];
        [self.currentFrame unlock];
        self.currentFrame = render;
#if SGPLATFORM_TARGET_OS_IPHONE
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
        {
            [self.glView display];
        }
#else
        [self.glView display];
#endif
    }
}

- (void)setupOpenGLIfNeeded
{
    if (!self.textureUploader) {
        self.textureUploader = [[SGGLTextureUploader alloc] initWithGLContext:self.glView.context];
    }
    if (!self.programPool) {
        self.programPool = [[SGGLProgramPool alloc] init];
    }
    if (!self.modelPool) {
        self.modelPool = [[SGGLModelPool alloc] init];
    }
}

#pragma mark - SGGLViewDelegate

- (BOOL)glView:(SGGLView *)glView draw:(SGGLSize)size
{
    SGFFVideoFrame * frame = self.currentFrame;
    if (!frame)
    {
        return NO;
    }
    [frame lock];

    [self setupOpenGLIfNeeded];

    id <SGGLModel> model = [self.modelPool modelWithType:SGGLModelTypePlane];
    id <SGGLProgram> program = [self.programPool programWithType:SGFFDMProgram(frame.format)];
    SGGLSize renderSize = {frame.width, frame.height};

    if (!model || !program || renderSize.width == 0 || renderSize.height == 0)
    {
        [frame unlock];
        return NO;
    }
    else
    {
        [program use];
        [program bindVariable];
        BOOL success = NO;
        if ([frame isKindOfClass:[SGFFVideoFFFrame class]])
        {
            success = [self.textureUploader uploadWithType:SGFFDMTexture(frame.format) data:frame.data size:renderSize];
        }
        else if ([frame isKindOfClass:[SGFFVideoAVFrame class]])
        {
            success = [self.textureUploader uploadWithCVPixelBuffer:((SGFFVideoAVFrame *)frame).corePixelBuffer];
        }
        if (!success)
        {
            [frame unlock];
            return NO;
        }
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        [model bindPosition_location:program.position_location textureCoordinate_location:program.textureCoordinate_location];
        [program updateModelViewProjectionMatrix:GLKMatrix4Identity];
        [SGGLViewport updateWithMode:SGGLViewportModeResizeAspect textureSize:renderSize layerSize:size scale:glView.glScale];
        [model draw];
        [model bindEmpty];
    }
    [frame unlock];
    return YES;
}

@end
