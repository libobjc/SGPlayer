//
//  SGObjectPool.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SGObjectPoolItemInterface \
@property (nonatomic, assign) NSInteger lockingCount;\

#define SGObjectPoolItemImplementation \
- (void)lock\
{\
    self.lockingCount++;\
}\
\
- (void)unlock\
{\
    self.lockingCount--;\
    if (self.lockingCount <= 0)\
    {\
        self.lockingCount = 0;\
        [[SGObjectPool sharePool] comeback:self];\
    }\
}\

#define SGObjectPoolItemLockingInterface      SGObjectPoolItemInterface
#define SGObjectPoolItemLockingImplementation SGObjectPoolItemImplementation

@protocol SGObjectPoolItem <NSObject>

- (void)lock;
- (void)unlock;
- (void)clear;

@end

@interface SGObjectPool : NSObject

+ (instancetype)sharePool;

- (__kindof id <SGObjectPoolItem>)objectWithClass:(Class)class;
- (void)comeback:(id <SGObjectPoolItem>)object;
- (void)flush;

@end
