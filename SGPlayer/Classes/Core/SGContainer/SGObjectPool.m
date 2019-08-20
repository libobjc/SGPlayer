//
//  SGObjectPool.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGObjectPool.h"

@interface SGObjectPool ()

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSMutableSet<id<SGData>> *> *pool;

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

- (id<SGData>)objectWithClass:(Class)class reuseName:(NSString *)reuseName
{
    [self->_lock lock];
    NSMutableSet <id<SGData>> *set = [self->_pool objectForKey:reuseName];
    if (!set) {
        set = [NSMutableSet set];
        [self->_pool setObject:set forKey:reuseName];
    }
    id<SGData> object = set.anyObject;
    if (object) {
        [set removeObject:object];
    } else {
        object = [[class alloc] init];
    }
    [object lock];
    object.reuseName = reuseName;
    [self->_lock unlock];
    return object;
}

- (void)comeback:(id<SGData>)object
{
    [self->_lock lock];
    NSMutableSet <id<SGData>> *set = [self->_pool objectForKey:object.reuseName];
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
