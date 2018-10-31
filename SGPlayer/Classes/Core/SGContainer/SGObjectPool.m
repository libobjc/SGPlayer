//
//  SGObjectPool.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGObjectPool.h"

@interface SGObjectPool ()

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableSet <id <SGObjectPoolItem>> *> * pool;

@end

@implementation SGObjectPool

+ (instancetype)sharePool
{
    static SGObjectPool * obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[SGObjectPool alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.coreLock = [[NSLock alloc] init];
        self.pool = [NSMutableDictionary dictionary];
    }
    return self;
}

- (__kindof id <SGObjectPoolItem>)objectWithClass:(Class)class
{
    [self.coreLock lock];
    NSString * className = NSStringFromClass(class);
    NSMutableSet <id <SGObjectPoolItem>> * set = [self.pool objectForKey:className];
    if (!set) {
        set = [NSMutableSet set];
        [self.pool setObject:set forKey:className];
    }
    id <SGObjectPoolItem> object = set.anyObject;
    if (object) {
        [set removeObject:object];
    } else {
        object = [[class alloc] init];
    }
    [object lock];
    [self.coreLock unlock];
    return object;
}

- (void)comeback:(id <SGObjectPoolItem>)object
{
    [self.coreLock lock];
    NSString * className = NSStringFromClass(object.class);
    NSMutableSet <id <SGObjectPoolItem>> * set = [self.pool objectForKey:className];
    if (![set containsObject:object]) {
        [set addObject:object];
        [object clear];
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
