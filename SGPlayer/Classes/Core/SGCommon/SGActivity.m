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
@property (nonatomic, strong) NSMutableSet * objects;

@end

@implementation SGActivity

+ (void)becomeActive:(id)object
{
    [[SGActivity activity] becomeActive:object];
}

+ (void)resignActive:(id)object
{
    [[SGActivity activity] resignActive:object];
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
    if (self = [super init])
    {
        self.coreLock = [[NSLock alloc] init];
        self.objects = [NSMutableSet set];
    }
    return self;
}

- (void)becomeActive:(id)object
{
    if (!object)
    {
        return;
    }
    [self.coreLock lock];
    if (![self.objects containsObject:[self token:object]])
    {
        [self.objects addObject:[self token:object]];
    }
    [self reload];
    [self.coreLock unlock];
}

- (void)resignActive:(id)object
{
    if (!object)
    {
        return;
    }
    [self.coreLock lock];
    if ([self.objects containsObject:[self token:object]])
    {
        [self.objects removeObject:[self token:object]];
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

- (id)token:(id)object
{
    return [NSString stringWithFormat:@"%p", object];
}

@end
