//
//  SGFFFramePool.h
//  SGPlayer
//
//  Created by Single on 2017/3/3.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFFrame.h"

@interface SGFFFramePool : NSObject

+ (instancetype)videoPool;
+ (instancetype)audioPool;
+ (instancetype)poolWithCapacity:(NSUInteger)number frameClassName:(Class)frameClassName;

- (NSUInteger)count;
- (NSUInteger)unuseCount;
- (NSUInteger)usedCount;

- (__kindof SGFFFrame *)getUnuseFrame;

- (void)flush;

@end
