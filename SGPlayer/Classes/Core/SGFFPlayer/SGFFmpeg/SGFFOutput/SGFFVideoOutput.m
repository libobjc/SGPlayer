//
//  SGFFVideoOutput.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoOutput.h"
#import "SGFFVideoOutputRender.h"
#import "SGPlayerMacro.h"
#import "SGGLDisplayLink.h"
#import "SGGLView.h"
#import "SGGLViewport.h"
#import "SGGLModelPool.h"
#import "SGGLProgramPool.h"
#import "SGGLTextureUploader.h"
#import "SGFFDefineMap.h"


@interface SGFFVideoOutput () <SGGLViewDelegate>

@property (nonatomic, strong) SGFFObjectQueue * frameQueue;
@property (nonatomic, strong) SGGLDisplayLink * displayLink;
@property (nonatomic, strong) SGFFVideoOutputRender * currentRender;
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
        self.glView = [[SGGLView alloc] initWithFrame:CGRectZero];
        self.glView.delegate = self;
        self.frameQueue = [[SGFFObjectQueue alloc] init];
        self.frameQueue.shouldSortObjects = YES;
        SGWeakSelf
        self.displayLink = [SGGLDisplayLink displayLinkWithCallback:^{
            SGStrongSelf
            [strongSelf displayLinkHandler];
        }];
    }
    return self;
}

- (void)dealloc
{
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
    [self.currentRender unlock];
    self.currentRender = nil;
}

- (void)putFrame:(__kindof SGFFFrame *)frame
{
    if (![frame isKindOfClass:[SGFFVideoFrame class]])
    {
        return;
    }
    SGFFVideoFrame * videoFrame = frame;
    
    SGFFVideoOutputRender * render = [[SGFFObjectPool sharePool] objectWithClass:[SGFFVideoOutputRender class]];
    [render updateCoreVideoFrame:videoFrame];
    [self.frameQueue putObjectSync:render];
    [self.delegate outputDidChangeCapacity:self];
    [render unlock];
}

- (void)flush
{
    [self.currentRender unlock];
    self.currentRender = nil;
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

#pragma mark - Renderer

- (void)displayLinkHandler
{
    SGFFVideoOutputRender * render = nil;
    if (self.currentRender)
    {
        SGWeakSelf
        render = [self.frameQueue getObjectAsyncWithPositionHandler:^BOOL(CMTime * current, CMTime * expect) {
            SGStrongSelf
            CMTime time = strongSelf.timeSynchronizer.position;
            NSAssert(CMTIME_IS_VALID(time), @"Key time is invalid.");
            NSTimeInterval interval = MAX(strongSelf.displayLink.nextVSyncTimestamp - CACurrentMediaTime(), 0);
            * expect = CMTimeAdd(time, SGFFTimeMakeWithSeconds(interval));
            * current = strongSelf.currentRender.position;
            return YES;
        }];
    }
    else
    {
        render = [self.frameQueue getObjectAsync];
    }
    if (render && render != self.currentRender)
    {
        [self.delegate outputDidChangeCapacity:self];
        [self.currentRender unlock];
        self.currentRender = render;
        [self.glView display];
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
    SGFFVideoOutputRender * render = self.currentRender;
    if (!render)
    {
        return NO;
    }
    [render lock];

    [self setupOpenGLIfNeeded];

    id <SGGLModel> model = [self.modelPool modelWithType:SGGLModelTypePlane];
    id <SGGLProgram> program = [self.programPool programWithType:SGFFDMProgram(render.coreVideoFrame.format)];
    SGGLSize renderSize = {render.coreVideoFrame.width, render.coreVideoFrame.height};

    if (!model || !program || renderSize.width == 0 || renderSize.height == 0)
    {
        [render unlock];
        return NO;
    }
    else
    {
        [program use];
        [program bindVariable];
        BOOL success = NO;
//        if (render.coreVideoFrame.corePixelBuffer)
//        {
//            success = [self.textureUploader uploadWithCVPixelBuffer:render.coreVideoFrame.corePixelBuffer];
//        }
//        else
            if (render.coreVideoFrame.coreFrame)
        {
            success = [self.textureUploader uploadWithType:SGFFDMTexture(render.coreVideoFrame.format) data:render.coreVideoFrame.data size:renderSize];
        }
        if (!success)
        {
            [render unlock];
            return NO;
        }
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        [model bindPosition_location:program.position_location textureCoordinate_location:program.textureCoordinate_location];
        [program updateModelViewProjectionMatrix:GLKMatrix4Identity];
        [SGGLViewport updateWithMode:SGGLViewportModeResizeAspect textureSize:renderSize layerSize:size scale:glView.glScale];
        [model draw];
        [model bindEmpty];
        [render unlock];
        return YES;
    }
    return YES;
}

@end
