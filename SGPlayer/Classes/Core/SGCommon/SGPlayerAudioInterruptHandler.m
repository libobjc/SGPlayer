//
//  SGPlayerAudioInterruptHandler.m
//  SGPlayer
//
//  Created by Single on 2018/1/15.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPlayerAudioInterruptHandler.h"
#import <AVFoundation/AVFoundation.h>
#import "SGPlayerBackgroundHandler.h"
#import "SGPlatform.h"

@interface SGPlayerAudioInterruptHandler ()

@property (nonatomic, weak) id <SGPlayer, SGPlayerPrivate> player;

@end

@implementation SGPlayerAudioInterruptHandler

#if SGPLATFORM_TARGET_OS_MAC

+ (instancetype)audioInterruptHandlerWithPlayer:(id <SGPlayer, SGPlayerPrivate>)player
{
    return nil;
}

#else

+ (instancetype)audioInterruptHandlerWithPlayer:(id <SGPlayer, SGPlayerPrivate>)player
{
    return [[self alloc] initWithPlayer:player];
}

- (instancetype)initWithPlayer:(id<SGPlayer,SGPlayerPrivate>)player
{
    if (self = [super init])
    {
        self.player = player;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(audioSessionInterruptionHandler:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(audioSessionRouteChangeHandler:)
                                                     name:AVAudioSessionRouteChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)audioSessionInterruptionHandler:(NSNotification *)notification
{
    AVAudioSessionInterruptionType type = [[notification.userInfo objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    AVAudioSessionInterruptionOptions option = [[notification.userInfo objectForKey:AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
    switch (type)
    {
        case AVAudioSessionInterruptionTypeBegan:
        {
            if (self.player.playbackState == SGPlayerPlaybackStatePlaying)
            {
                // Fix : Sometimes will receive interruption notification when enter foreground.
                NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
                NSTimeInterval lastWillEnterForegroundTimeInterval = [SGPlayerBackgroundHandler lastWillEnterForegroundTimeInterval];
                if (timeInterval - lastWillEnterForegroundTimeInterval > 1.5)
                {
                    [self.player interrupt];
                }
            }
        }
            break;
        case AVAudioSessionInterruptionTypeEnded:
        {
            if (option & AVAudioSessionInterruptionOptionShouldResume)
            {
                if (self.player.playbackState == SGPlayerPlaybackStateInterrupted)
                {
                    [self.player play];
                }
            }
        }
            break;
        default:
            break;
    }
}

- (void)audioSessionRouteChangeHandler:(NSNotification *)notification
{
    AVAudioSessionRouteChangeReason reason = [[notification.userInfo objectForKey:AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue];
    switch (reason) {
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
            if (self.player.playbackState == SGPlayerPlaybackStatePlaying)
            {
                [self.player pause];
            }
        }
            break;
        default:
            break;
    }
}

#endif

@end
