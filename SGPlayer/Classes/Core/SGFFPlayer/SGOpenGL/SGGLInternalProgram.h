//
//  SGGLInternalProgram.h
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPLFOpenGL.h"

@interface SGGLInternalProgram : NSObject

@property (nonatomic, assign, readonly) GLint programID;

- (void)updateModelViewProjectionMatrix:(GLKMatrix4)matrix;
- (void)use;


#pragma mark - Override

@property (nonatomic, assign, readonly) const char * vertex_shader_string;
@property (nonatomic, assign, readonly) const char * fragment_shader_string;

@property (nonatomic, assign) GLint position_location;
@property (nonatomic, assign) GLint texture_coordinate_location;
@property (nonatomic, assign) GLint model_view_projection_location;

- (void)loadVariable;
- (void)bindVariable;

@end
