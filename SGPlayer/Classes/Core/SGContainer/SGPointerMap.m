//
//  SGPointerMap.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/31.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPointerMap.h"

@interface SGPointerMap ()

@property (nonatomic, strong) NSMutableDictionary * keys;
@property (nonatomic, strong) NSMutableDictionary * objects;

@end

@implementation SGPointerMap

- (instancetype)init
{
    if (self = [super init]) {
        self.keys = [[NSMutableDictionary alloc] init];
        self.objects = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setObject:(id)object forKey:(id)key
{
    NSAssert(object, @"Invalid object");
    NSString * p = [self pointerForObject:key];
    [self.keys setObject:key forKey:p];
    [self.objects setObject:object forKey:p];
}

- (id)objectForKey:(id)key
{
    if (!key) {
        return nil;
    }
    NSString * p = [self pointerForObject:key];
    return [self.objects objectForKey:p];
}

- (void)removeObjectForKey:(id)key
{
    NSString * p = [self pointerForObject:key];
    [self.keys removeObjectForKey:p];
    [self.objects removeObjectForKey:p];
}

- (void)removeAllObjects
{
    [self.keys removeAllObjects];
    [self.objects removeAllObjects];
}

- (NSString *)pointerForObject:(id)object
{
    NSAssert(object, @"Invalid key");
    return [NSString stringWithFormat:@"%p", object];
}

@end
