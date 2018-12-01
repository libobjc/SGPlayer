//
//  SGObjectPool.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SGObjectPoolItem;

@interface SGObjectPool : NSObject

+ (instancetype _Nonnull)sharedPool;

/**
 *
 */
- (__kindof id<SGObjectPoolItem> _Nonnull)objectWithClass:(Class _Nonnull)class;

/**
 *
 */
- (void)comeback:(id<SGObjectPoolItem> _Nonnull)object;

/**
 *
 */
- (void)flush;

@end

@protocol SGObjectPoolItem <NSObject>

/**
 *
 */
- (void)lock;

/**
 *
 */
- (void)unlock;

/**
 *
 */
- (void)clear;

@end
