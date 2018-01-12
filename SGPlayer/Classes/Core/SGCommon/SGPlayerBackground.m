//
//  SGPlayerBackground.m
//  SGPlayer
//
//  Created by Single on 2018/1/12.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPlayerBackground.h"
#import "SGPLFObject.h"

@implementation SGPlayerBackground

- (void)becomeActive:(id<SGPlayer>)player
{
    [[NSNotificationCenter defaultCenter] addObserver:player
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:player
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)resignActive:(id<SGPlayer>)player
{
    [[NSNotificationCenter defaultCenter] removeObserver:player];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    if ([self.delegate respondsToSelector:@selector(backgroundWillEnterForeground:)]) {
        [self.delegate backgroundWillEnterForeground:self];
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    if ([self.delegate respondsToSelector:@selector(backgroundDidEnterBackground:)]) {
        [self.delegate backgroundDidEnterBackground:self];
    }
}

@end
