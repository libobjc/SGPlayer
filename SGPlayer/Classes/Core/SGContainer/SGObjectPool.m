//
//  SGObjectPool.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGObjectPool.h"

@interface SGObjectPool ()

{
    NSLock *_lock;
    NSMutableDictionary<NSString *, NSMutableSet<id<SGData>> *> *_pool;
}

@end

@implementation SGObjectPool

+ (instancetype)sharedPool
{
    static SGObjectPool *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[SGObjectPool alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_pool = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id<SGData>)objectWithClass:(Class)class
{
    [self->_lock lock];
    NSString *className = NSStringFromClass(class);
    NSMutableSet <id<SGData>> *set = [self->_pool objectForKey:className];
    if (!set) {
        set = [NSMutableSet set];
        [self->_pool setObject:set forKey:className];
    }
    id<SGData> object = set.anyObject;
    if (object) {
        [set removeObject:object];
    } else {
        object = [[class alloc] init];
    }
    [object lock];
    [self->_lock unlock];
    return object;
}

- (void)comeback:(id<SGData>)object
{
    [self->_lock lock];
    NSString *className = NSStringFromClass(object.class);
    NSMutableSet <id<SGData>> *set = [self->_pool objectForKey:className];
    if (![set containsObject:object]) {
        [set addObject:object];
        [object clear];
    }
    [self->_lock unlock];
}

- (void)flush
{
    [self->_lock lock];
    [self->_pool removeAllObjects];
    [self->_lock unlock];
}

@end
