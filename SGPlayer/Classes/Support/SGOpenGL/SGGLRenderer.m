//
//  SGGLRenderer.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGGLRenderer.h"
#import "SGGLModelPool.h"
#import "SGGLProgramPool.h"

@interface SGGLRenderer ()

@property (nonatomic, strong) SGGLModelPool * modelPool;
@property (nonatomic, strong) SGGLProgramPool * programPool;
@property (nonatomic, strong) id <SGGLModel> model;
@property (nonatomic, strong) id <SGGLProgram> program;

@end

@implementation SGGLRenderer

- (BOOL)bind
{
    if (!self.programPool)
    {
        self.programPool = [[SGGLProgramPool alloc] init];
    }
    if (!self.modelPool)
    {
        self.modelPool = [[SGGLModelPool alloc] init];
    }
    self.model = [self.modelPool modelWithType:self.modelType];
    self.program = [self.programPool programWithType:self.programType];
    if (!self.model || !self.program)
    {
        return NO;
    }
    [self.program use];
    [self.program bindVariable];
    return YES;
}

- (void)unbind
{
    [self.model unbind];
    [self.program unuse];
}

- (void)draw
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self.model bindPosition_location:self.program.position_location
           textureCoordinate_location:self.program.textureCoordinate_location];
    [self.program updateModelViewProjectionMatrix:GLKMatrix4Identity];
    [SGGLViewport updateWithMode:self.viewportMode
                     textureSize:self.textureSize
                       layerSize:self.layerSize
                           scale:self.scale];
    [self.model draw];
}

@end
