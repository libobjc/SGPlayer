//
//  SGObjectPool.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGData.h"

@interface SGObjectPool : NSObject

+ (instancetype _Nonnull)sharedPool;

/**
 *
 */
- (__kindof id<SGData> _Nonnull)objectWithClass:(Class _Nonnull)class;

/**
 *
 */
- (void)comeback:(id<SGData> _Nonnull)object;

/**
 *
 */
- (void)flush;

@end
