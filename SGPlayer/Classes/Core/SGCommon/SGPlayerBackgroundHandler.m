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

@property (nonatomic, weak) id <SGPlayer> player;
@property (nonatomic, assign) BOOL shouldAutoPlay;

@end

@implementation SGPlayerBackgroundHandler

static NSTimeInterval lastWillEnterForegroundTimeInterval = 0;
static NSTimeInterval lastDidEnterBackgroundTimeInterval = 0;

+ (NSTimeInterval)lastWillEnterForegroundTimeInterval
{
    return lastWillEnterForegroundTimeInterval;
}

+ (NSTimeInterval)lastDidEnterBackgroundTimeInterval
{
    return lastDidEnterBackgroundTimeInterval;
}

#if SGPLATFORM_TARGET_OS_MAC

+ (instancetype)backgroundHandlerWithPlayer:(id <SGPlayer>)player
{
    return nil;
}

#else

+ (instancetype)backgroundHandlerWithPlayer:(id <SGPlayer>)player
{
    return [[self alloc] initWithPlayer:player];
}

- (instancetype)initWithPlayer:(id <SGPlayer>)player
{
    if (self = [super init])
    {
        self.player = player;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    lastWillEnterForegroundTimeInterval = [NSDate date].timeIntervalSince1970;
    if (self.shouldAutoPlay)
    {
        self.shouldAutoPlay = NO;
        if (self.player.backgroundMode == SGPlayerBackgroundModeAutoPlayAndPause)
        {
            if (self.player.playbackState == SGPlayerPlaybackStatePaused)
            {
                [self.player play];
            }
        }
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    lastDidEnterBackgroundTimeInterval = [NSDate date].timeIntervalSince1970;
    if (self.player.backgroundMode == SGPlayerBackgroundModeAutoPlayAndPause)
    {
        if (self.player.playbackState == SGPlayerPlaybackStatePlaying)
        {
            self.shouldAutoPlay = YES;
            [self.player pause];
        }
    }
}

#endif

@end
