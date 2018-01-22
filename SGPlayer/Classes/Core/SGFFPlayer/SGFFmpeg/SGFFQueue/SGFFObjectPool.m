//
//  SGFFObjectPool.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFObjectPool.h"

@interface SGFFObjectPool ()

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableSet <id <SGFFObjectPoolItem>> *> * pool;

@end

@implementation SGFFObjectPool

+ (instancetype)sharePool
{
    static SGFFObjectPool * obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[SGFFObjectPool alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.coreLock = [[NSLock alloc] init];
        self.pool = [NSMutableDictionary dictionary];
    }
    return self;
}

- (__kindof id <SGFFObjectPoolItem>)objectWithClass:(Class)class
{
    [self.coreLock lock];
    NSString * className = NSStringFromClass(class);
    NSMutableSet <id <SGFFObjectPoolItem>> * set = [self.pool objectForKey:className];
    if (!set)
    {
        set = [NSMutableSet set];
        [self.pool setObject:set forKey:className];
    }
    id <SGFFObjectPoolItem> object = set.anyObject;
    if (object) {
        [set removeObject:object];
    } else {
        object = [[class alloc] init];
    }
    [object lock];
    [self.coreLock unlock];
    return object;
}

- (void)comeback:(__kindof id <SGFFObjectPoolItem>)object
{
    [self.coreLock lock];
    NSString * className = NSStringFromClass(object.class);
    NSMutableSet <id <SGFFObjectPoolItem>> * set = [self.pool objectForKey:className];
    if (![set containsObject:object]) {
        [set addObject:object];
    }
    [self.coreLock unlock];
}

- (void)flush
{
    [self.coreLock lock];
    [self.pool removeAllObjects];
    [self.coreLock unlock];
}

@end
