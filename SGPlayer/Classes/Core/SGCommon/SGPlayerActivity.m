//
//  SGPlayerActivity.m
//  SGPlayer
//
//  Created by Single on 2018/1/10.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPlayerActivity.h"
#import "SGPLFObject.h"

@interface SGPlayerActivity ()

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) NSMutableSet * players;

@end

@implementation SGPlayerActivity


#pragma mark - Interface

+ (void)becomeActive:(id<SGPlayer>)player
{
    [[SGPlayerActivity activity] becomeActive:player];
}

+ (void)resignActive:(id<SGPlayer>)player
{
    [[SGPlayerActivity activity] resignActive:player];
}


#pragma mark - Class

+ (instancetype)activity
{
    static SGPlayerActivity * obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[SGPlayerActivity alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.coreLock = [[NSLock alloc] init];
        self.players = [NSMutableSet set];
    }
    return self;
}

- (void)becomeActive:(id<SGPlayer>)player
{
    if (player == nil) {
        return;
    }
    [self.coreLock lock];
    if (![self.players containsObject:@(player.tag)])
    {
        [self.players addObject:@(player.tag)];
    }
    [self reload];
    [self.coreLock unlock];
}

- (void)resignActive:(id<SGPlayer>)player
{
    if (player == nil) {
        return;
    }
    [self.coreLock lock];
    if ([self.players containsObject:@(player.tag)])
    {
        [self.players removeObject:@(player.tag)];
    }
    [self reload];
    [self.coreLock unlock];
}

- (void)reload
{
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    BOOL disable = self.players.count <= 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].idleTimerDisabled = disable;
    });
#endif
}

@end
