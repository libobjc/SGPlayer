//
//  SGPlayerActivity.m
//  SGPlayer
//
//  Created by Single on 2018/1/10.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGActivity.h"
#import <UIKit/UIKit.h>

@interface SGActivity ()

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) NSMutableSet * targets;

@end

@implementation SGActivity

+ (void)addTarget:(id)target
{
    [[SGActivity activity] addTarget:target];
}

+ (void)removeTarget:(id)target
{
    [[SGActivity activity] removeTarget:target];
}


#pragma mark - Class

+ (instancetype)activity
{
    static SGActivity * obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[SGActivity alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.coreLock = [[NSLock alloc] init];
        self.targets = [NSMutableSet set];
    }
    return self;
}

- (void)addTarget:(id)target
{
    if (!target) {
        return;
    }
    [self.coreLock lock];
    if (![self.targets containsObject:[self token:target]]) {
        [self.targets addObject:[self token:target]];
    }
    [self reload];
    [self.coreLock unlock];
}

- (void)removeTarget:(id)target
{
    if (!target) {
        return;
    }
    [self.coreLock lock];
    if ([self.targets containsObject:[self token:target]]) {
        [self.targets removeObject:[self token:target]];
    }
    [self reload];
    [self.coreLock unlock];
}

- (void)reload
{
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    BOOL disable = self.objects.count <= 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].idleTimerDisabled = disable;
    });
#endif
}

- (id)token:(id)target
{
    return [NSString stringWithFormat:@"%p", target];
}

@end
