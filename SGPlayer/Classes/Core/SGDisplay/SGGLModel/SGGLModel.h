//
//  SGGLModel.h
//  SGPlayer
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface SGGLModel : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)model;

@property (nonatomic, assign) GLuint index_id;
@property (nonatomic, assign) GLuint vertex_id;
@property (nonatomic, assign) GLuint texture_id;

@property (nonatomic, assign) int index_count;
@property (nonatomic, assign) int vertex_count;

- (void)bindPositionLocation:(GLint)position_location textureCoordLocation:(GLint)textureCoordLocation;

#pragma mark - subclass override

- (void)setupModel;

@end
