//
//  SGFFOutputRender.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGFFOutputRender_h
#define SGFFOutputRender_h


#import <Foundation/Foundation.h>
#import "SGFFObjectPool.h"
#import "SGFFObjectQueue.h"
#import "SGFFTime.h"


@protocol SGFFOutputRender <NSObject, SGFFObjectPoolItem, SGFFObjectQueueItem>

- (SGFFTimebase)timebase;
- (long long)position;
- (long long)duration;
- (long long)size;

@end


#endif /* SGFFOutputRender_h */
