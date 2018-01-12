//
//  SGPlayerBackgroundHandler.m
//  SGPlayer
//
//  Created by Single on 2018/1/12.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPlayerBackgroundHandler.h"
#import "SGPLFObject.h"

@interface SGPlayerBackgroundHandler ()

@property (nonatomic, weak) id<SGPlayer> player;
@property (nonatomic, assign) BOOL shouldAutoPlay;

@end

@implementation SGPlayerBackgroundHandler

- (void)becomeActive:(id<SGPlayer>)player
{
    self.player = player;
    
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
    if (self.player.backgroundMode == SGPlayerBackgroundModeAutoPlayAndPause)
    {
        if (self.shouldAutoPlay)
        {
            self.shouldAutoPlay = NO;
            if (self.player.playbackState == SGPlayerPlaybackStatePaused)
            {
                [self.player play];
            }
        }
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    if (self.player.backgroundMode == SGPlayerBackgroundModeAutoPlayAndPause)
    {
        if (self.player.playbackState == SGPlayerPlaybackStatePlaying)
        {
            self.shouldAutoPlay = YES;
            [self.player pause];
        }
    }
}

@end
