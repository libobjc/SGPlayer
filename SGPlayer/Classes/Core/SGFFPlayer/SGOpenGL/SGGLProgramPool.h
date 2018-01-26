//
//  SGGLProgramPool.h
//  SGPlayer
//
//  Created by Single on 2018/1/26.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGGLProgram.h"

typedef NS_ENUM(NSUInteger, SGGLProgramType)
{
    SGGLProgramTypeUnknown,
    SGGLProgramTypeYUV420P,
    SGGLProgramTypeNV12,
};

@interface SGGLProgramPool : NSObject

- (id <SGGLProgram>)programWithType:(SGGLProgramType)type;

@end
