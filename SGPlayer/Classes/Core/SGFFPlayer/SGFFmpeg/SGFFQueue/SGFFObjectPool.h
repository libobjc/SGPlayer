//
//  SGFFObjectPool.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SGFFObjectPoolItem <NSObject>

- (void)lock;
- (void)unlock;

@end

@interface SGFFObjectPool : NSObject

+ (instancetype)sharePool;

- (__kindof id <SGFFObjectPoolItem>)objectWithClass:(Class)class;
- (void)comeback:(__kindof id <SGFFObjectPoolItem>)object;
- (void)flush;

@end
