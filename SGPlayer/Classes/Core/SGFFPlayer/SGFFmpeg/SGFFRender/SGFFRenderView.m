//
//  SGFFRenderView.m
//  SGPlayer
//
//  Created by Single on 2018/6/25.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFFRenderView.h"
#import "SGGLView.h"
#import "SGGLViewport.h"
#import "SGGLModelPool.h"
#import "SGGLProgramPool.h"
#import "SGGLTextureUploader.h"
#import "SGFFVideoOutputRender.h"
#import "SGFFDefineMap.h"

@interface SGFFRenderView () <SGGLViewDelegate>

@property (nonatomic, strong) SGGLView * glView;
@property (nonatomic, strong) SGGLModelPool * modelPool;
@property (nonatomic, strong) SGGLProgramPool * programPool;
@property (nonatomic, strong) SGGLTextureUploader * textureUploader;
@property (nonatomic, strong) SGFFVideoOutputRender * currentRender;

@end

@implementation SGFFRenderView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.glView = [[SGGLView alloc] initWithFrame:CGRectZero];
        self.glView.delegate = self;
        [self addSubview:self.glView];
    }
    return self;
}

- (void)dealloc
{
    [self.currentRender unlock];
    [self.glView removeFromSuperview];
    self.glView = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.glView.frame = self.bounds;
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

- (void)prensentRender:(id <SGFFOutputRender>)render
{
    [render lock];
    [self.currentRender unlock];
    self.currentRender = render;
    [self.glView display];
}

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
        if (render.coreVideoFrame.corePixelBuffer)
        {
            success = [self.textureUploader uploadWithCVPixelBuffer:render.coreVideoFrame.corePixelBuffer];
        }
        else if (render.coreVideoFrame.coreFrame)
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
}

@end
