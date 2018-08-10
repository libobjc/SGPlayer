//
//  SGGLRenderer.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGGLDefines.h"
#import "SGGLModel.h"
#import "SGGLProgram.h"
#import "SGGLViewport.h"

@interface SGGLRenderer : NSObject

@property (nonatomic, assign) SGGLModelType modelType;
@property (nonatomic, assign) SGGLProgramType programType;
@property (nonatomic, assign) SGGLViewportMode viewportMode;
@property (nonatomic, assign) SGGLSize textureSize;
@property (nonatomic, assign) SGGLSize layerSize;
@property (nonatomic, assign) double scale;

- (BOOL)bind;
- (void)unbind;
- (void)draw;

@end
