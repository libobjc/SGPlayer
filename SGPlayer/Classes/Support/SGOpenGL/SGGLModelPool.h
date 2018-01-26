//
//  SGGLModelPool.h
//  SGPlayer
//
//  Created by Single on 2018/1/26.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGGLModel.h"

typedef NS_ENUM(NSUInteger, SGGLModelType)
{
    SGGLModelTypeUnknown,
    SGGLModelTypePlane,
    SGGLModelTypeSphere,
};

@interface SGGLModelPool : NSObject

- (id <SGGLModel>)modelWithType:(SGGLModelType)type;

@end
