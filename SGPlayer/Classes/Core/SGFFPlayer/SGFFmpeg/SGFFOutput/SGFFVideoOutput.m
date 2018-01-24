//
//  SGFFVideoOutput.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoOutput.h"
#import "SGFFVideoOutputRender.h"
#import "SGGLView.h"
#import "SGGLProgramYUV420.h"
#import "SGGLNormalModel.h"
#import "SGGLTextureYUV420.h"
#import "SGPlatform.h"

@interface SGFFVideoOutput () <SGGLViewDelegate>

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) SGGLView * glView;
@property (nonatomic, strong) SGGLProgramYUV420 * program;
@property (nonatomic, strong) SGGLNormalModel * model;
@property (nonatomic, strong) SGGLTextureYUV420 * texture;
@property (nonatomic, strong) SGPLFDisplayLink * displayLink;
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
        self.displayLink = [SGPLFDisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction)];
        self.displayLink.preferredFramesPerSecond = 25;
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        self.displayLink.paused = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.glView = [[SGGLView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
            self.glView.delegate = self;
            [self.delegate videoOutputDidChangeDisplayView:self];
        });
    }
    return self;
}

- (SGPLFView *)displayView
{
    return self.glView;
}

- (void)displayLinkAction
{
    SGFFVideoOutputRender * render = [self.renderSource outputFecthRender:self];
    if (render)
    {
        [self.coreLock lock];
        [self.currentRender unlock];
        [self.coreLock unlock];
        self.currentRender = render;
        [self.glView display];
    }
}

- (void)setupOpenGLIfNeed
{
    if (!self.texture) {
        self.texture = [[SGGLTextureYUV420 alloc] init];
    }
    if (!self.program) {
        self.program = [SGGLProgramYUV420 program];
    }
    if (!self.model) {
        self.model = [SGGLNormalModel model];
    }
}


#pragma mark - SGGLViewDelegate

- (void)glViewDrawDisplay:(SGGLView *)glView
{
    [self.coreLock lock];
    SGFFVideoOutputRender * render = self.currentRender;
    if (!render)
    {
        [self.coreLock unlock];
    }
    else
    {
        [render lock];
        [self.coreLock unlock];
        [self setupOpenGLIfNeed];
        [self.program use];
        [self.program bindVariable];
        [self.texture updateTexture:render];
        [self.model bindPositionLocation:self.program.position_location
                    textureCoordLocation:self.program.texture_coord_location
                       textureRotateType:SGGLModelTextureRotateType0];
        [self.program updateMatrix:GLKMatrix4Identity];
        
        int viewport[4];
        double renderAspect = (double)render.videoFrame.width / render.videoFrame.height;
        double displayAspect = (double)self.glView.displaySize.width / self.glView.displaySize.height;
        if (fabs(displayAspect - renderAspect) <= 0.0001)
        {
            viewport[0] = 0;
            viewport[1] = 0;
            viewport[2] = self.glView.displaySize.width;
            viewport[3] = self.glView.displaySize.height;
        }
        else if (displayAspect < renderAspect)
        {
            CGFloat height = self.glView.displaySize.width / renderAspect;
            viewport[0] = 0;
            viewport[1] = (self.glView.displaySize.height - height) / 2;
            viewport[2] = self.glView.displaySize.width;
            viewport[3] = height;
        }
        else if (displayAspect > renderAspect)
        {
            CGFloat width = self.glView.displaySize.height * renderAspect;
            viewport[0] = (self.glView.displaySize.width - width) / 2;
            viewport[1] = 0;
            viewport[2] = width;
            viewport[3] = self.glView.displaySize.height;
        }
        glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
        
        glDrawElements(GL_TRIANGLES, self.model.index_count, GL_UNSIGNED_SHORT, 0);
        [render unlock];
    }
}

@end
