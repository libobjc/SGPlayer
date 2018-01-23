//
//  SGGLModel.m
//  SGPlayer
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLModel.h"
#import "SGPlayerMacro.h"

@implementation SGGLModel

+ (instancetype)model
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setupModel];
    }
    return self;
}

- (void)dealloc
{
    SGPlayerLog(@"%@ release", self.class);
}

#pragma mark - subclass override

- (void)setupModel {}
- (void)bindPositionLocation:(GLint)position_location
        textureCoordLocation:(GLint)textureCoordLocation {}
- (void)bindPositionLocation:(GLint)position_location
        textureCoordLocation:(GLint)textureCoordLocation
           textureRotateType:(SGGLModelTextureRotateType)textureRotateType {}

@end
