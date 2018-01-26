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
#import "SGGLView.h"
#import "SGGLViewport.h"
#import "SGGLModelPool.h"
#import "SGGLProgramPool.h"
#import "SGGLDisplayLink.h"
#import "SGGLTextureUploader.h"
#import "SGFFDefineMap.h"

@interface SGFFVideoOutput () <SGGLViewDelegate>

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) SGGLView * glView;
@property (nonatomic, strong) SGGLModelPool * modelPool;
@property (nonatomic, strong) SGGLProgramPool * programPool;
@property (nonatomic, strong) SGGLDisplayLink * displayLink;
@property (nonatomic, strong) SGGLTextureUploader * textureUploader;
@property (nonatomic, strong) SGFFVideoOutputRender * currentRender;

@end

@implementation SGFFVideoOutput

- (id <SGFFOutputRender>)renderWithFrame:(id <SGFFFrame>)frame
{
    SGFFVideoOutputRender * render = [[SGFFObjectPool sharePool] objectWithClass:[SGFFVideoOutputRender class]];
    [render updateVideoFrame:frame.videoFrame];
    return render;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.coreLock = [[NSLock alloc] init];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.glView = [[SGGLView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
            self.glView.delegate = self;
            [self.delegate videoOutputDidChangeDisplayView:self];
            SGWeakSelf
            self.displayLink = [SGGLDisplayLink displayLinkWithCallback:^{
                SGStrongSelf
                [strongSelf displayLinkHandler];
            }];
        });
    }
    return self;
}

- (void)dealloc
{
    [self.displayLink invalidate];
    if (self.currentRender)
    {
        [self.coreLock lock];
        [self.currentRender unlock];
        self.currentRender = nil;
        [self.coreLock unlock];
    }
}

- (SGPLFView *)displayView
{
    return self.glView;
}

- (void)displayLinkHandler
{
    SGFFVideoOutputRender * render = [self.renderSource outputFecthRender:self];
    if (render)
    {
        [self.coreLock lock];
        if (self.currentRender != render)
        {
            [self.currentRender unlock];
            self.currentRender = render;
        }
        [self.coreLock unlock];
        [self.glView display];
    }
}

- (void)setupOpenGLIfNeed
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
    [self.coreLock lock];
    SGFFVideoOutputRender * render = self.currentRender;
    if (!render)
    {
        [self.coreLock unlock];
        return NO;
    }
    [render lock];
    [self.coreLock unlock];
    
    [self setupOpenGLIfNeed];
    
    id <SGGLModel> model = [self.modelPool modelWithType:SGGLModelTypePlane];
    id <SGGLProgram> program = [self.programPool programWithType:SGFFDMProgram(render.videoFrame.format)];
    SGGLSize renderSize = {render.videoFrame.width, render.videoFrame.height};
    
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
        if (render.videoFrame.corePixelBuffer)
        {
            success = [self.textureUploader uploadWithCVPixelBuffer:render.videoFrame.corePixelBuffer];
        }
        else if (render.videoFrame.coreFrame)
        {
            success = [self.textureUploader uploadWithType:SGFFDMTexture(render.videoFrame.format) data:render.videoFrame.data size:renderSize];
        }
        if (!success)
        {
            [render unlock];
            return NO;
        }
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        [model bindPosition_location:program.position_location textureCoordinate_location:program.textureCoordinate_location];
        [program updateModelViewProjectionMatrix:GLKMatrix4Identity];
        [SGGLViewport updateWithMode:SGGLViewportModeResizeAspect textureSize:renderSize layerSize:size];
        [model draw];
        [model bindEmpty];
        [render unlock];
        return YES;
    }
}

@end
