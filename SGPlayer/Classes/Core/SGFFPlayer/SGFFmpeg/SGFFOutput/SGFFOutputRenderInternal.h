//
//  SGFFOutputRenderInternal.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFOutputRender.h"

@interface SGFFOutputRenderInternal : NSObject <SGFFOutputRender>

@property (nonatomic, assign) long long position;
@property (nonatomic, assign) long long duration;
@property (nonatomic, assign) long long size;

@end
