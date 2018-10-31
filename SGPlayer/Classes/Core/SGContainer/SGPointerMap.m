//
//  SGPointerMap.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/31.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPointerMap.h"

@interface SGPointerMap ()

@property (nonatomic, strong) NSMutableDictionary * objects;

@end

@implementation SGPointerMap

- (instancetype)init
{
    if (self = [super init]) {
        self.objects = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setObject:(id)object forKey:(id)key
{
    NSAssert(object, @"Invalid object");
    [self.objects setObject:object forKey:[self keyForObject:key]];
}

- (id)objectForKey:(id)key
{
    return [self.objects objectForKey:[self keyForObject:key]];
}

- (void)removeObjectForKey:(id)key
{
    [self.objects removeObjectForKey:[self keyForObject:key]];
}

- (void)removeAllObjects
{
    [self.objects removeAllObjects];
}

- (NSString *)keyForObject:(id)object
{
    NSAssert(object, @"Invalid key");
    return [NSString stringWithFormat:@"%p", object];
}

@end
