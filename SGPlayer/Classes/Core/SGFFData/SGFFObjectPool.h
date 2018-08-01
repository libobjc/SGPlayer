//
//  SGFFObjectPool.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>


#define SGFFObjectPoolItemInterface \
@property (nonatomic, assign) NSInteger lockingCount;\


#define SGFFObjectPoolItemImplementation \
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
        [[SGFFObjectPool sharePool] comeback:self];\
    }\
}\


#define SGFFObjectPoolItemLockingInterface      SGFFObjectPoolItemInterface
#define SGFFObjectPoolItemLockingImplementation SGFFObjectPoolItemImplementation


@protocol SGFFObjectPoolItem <NSObject, NSLocking>

- (void)clear;

@end

@interface SGFFObjectPool : NSObject

+ (instancetype)sharePool;

- (__kindof id <SGFFObjectPoolItem>)objectWithClass:(Class)class;
- (void)comeback:(__kindof id <SGFFObjectPoolItem>)object;
- (void)flush;

@end
