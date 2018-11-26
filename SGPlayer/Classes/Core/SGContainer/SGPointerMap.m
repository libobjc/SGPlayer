//
//  SGPointerMap.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/31.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPointerMap.h"

@interface SGPointerMap ()

{
    NSMutableDictionary *_keys;
    NSMutableDictionary *_objects;
}

@end

@implementation SGPointerMap

- (instancetype)init
{
    if (self = [super init]) {
        self->_keys = [[NSMutableDictionary alloc] init];
        self->_objects = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setObject:(id)object forKey:(id)key
{
    NSAssert(object, @"Invalid object");
    NSString *p = [self pointerForObject:key];
    [self->_keys setObject:key forKey:p];
    [self->_objects setObject:object forKey:p];
}

- (id)objectForKey:(id)key
{
    if (!key) {
        return nil;
    }
    NSString *p = [self pointerForObject:key];
    return [self->_objects objectForKey:p];
}

- (void)removeObjectForKey:(id)key
{
    NSString *p = [self pointerForObject:key];
    [self->_keys removeObjectForKey:p];
    [self->_objects removeObjectForKey:p];
}

- (void)removeAllObjects
{
    [self->_keys removeAllObjects];
    [self->_objects removeAllObjects];
}

- (NSString *)pointerForObject:(id)object
{
    NSAssert(object, @"Invalid key");
    return [NSString stringWithFormat:@"%p", object];
}

@end
