//
//  SGFFOutputRenderQueue.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFOutputRender.h"

@interface SGFFOutputRenderQueue : NSObject

- (instancetype)initWithMaxCount:(NSInteger)maxCount;

- (NSInteger)count;
- (long long)duration;
- (long long)size;

- (void)putObjectSync:(id <SGFFOutputRender>)object;
- (void)putObjectAsync:(id <SGFFOutputRender>)object;
- (id <SGFFOutputRender>)getObjectSync;
- (id <SGFFOutputRender>)getObjectAsync;

- (void)flush;
- (void)destroy;

@end
