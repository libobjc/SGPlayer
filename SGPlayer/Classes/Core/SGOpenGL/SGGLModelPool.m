//
//  SGGLModelPool.m
//  SGPlayer
//
//  Created by Single on 2018/1/26.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLModelPool.h"
#import "SGGLPlaneModel.h"
#import "SGGLSphereModel.h"

@interface SGGLModelPool ()

@property (nonatomic, strong) SGGLPlaneModel *plane;
@property (nonatomic, strong) SGGLSphereModel *sphere;

@end

@implementation SGGLModelPool

- (id<SGGLModel>)modelWithType:(SGGLModelType)type
{
    switch (type) {
        case SGGLModelTypeUnknown:
            return nil;
        case SGGLModelTypePlane:
            return self.plane;
        case SGGLModelTypeSphere:
            return self.sphere;
    }
    return nil;
}

- (SGGLPlaneModel *)plane
{
    if (!_plane) {
        _plane = [[SGGLPlaneModel alloc] init];
    }
    return _plane;
}

- (SGGLSphereModel *)sphere
{
    if (!_sphere) {
        _sphere = [[SGGLSphereModel alloc] init];
    }
    return _sphere;
}

@end
