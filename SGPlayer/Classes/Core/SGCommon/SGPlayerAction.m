//
//  SGPlayerAction.m
//  SGPlayer
//
//  Created by Single on 2017/2/13.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPlayerAction.h"


// notification name
NSString * const SGPlayerPlaybackStateDidChangeNotificationName = @"SGPlayerPlaybackStateDidChangeNotificationName";     // player state change
NSString * const SGPlayerLoadStateDidChangeNotificationName = @"SGPlayerLoadStateDidChangeNotificationName";     // player state change
NSString * const SGPlayerPlaybackTimeDidChangeNotificationName = @"SGPlayerPlaybackTimeDidChangeNotificationName";  // player play progress change
NSString * const SGPlayerLoadedTimeDidChangeNotificationName = @"SGPlayerLoadedTimeDidChangeNotificationName";   // player playable progress change
NSString * const SGPlayerDidErrorNotificationName = @"SGPlayerDidErrorNotificationName";                   // player error

NSString * const SGPlayerNotificationUserInfoObjectKey = @"SGPlayerNotificationUserInfoObjectKey";    // state


#pragma mark - SGPlayer Action Category

@implementation NSObject (SGPlayerAction)

- (void)sg_registerNotificationForPlayer:(id)player
                     playbackStateAction:(SEL)playbackStateAction
                         loadStateAction:(SEL)loadStateAction
                      playbackTimeAction:(SEL)playbackTimeAction
                            loadedAction:(SEL)loadedAction
                             errorAction:(SEL)errorAction
{
    [self sg_removeNotificationForPlayer:player];
    
    if (playbackStateAction) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:playbackStateAction
                                                     name:SGPlayerPlaybackStateDidChangeNotificationName
                                                   object:player];
    }
    if (loadStateAction) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:loadStateAction
                                                     name:SGPlayerLoadStateDidChangeNotificationName
                                                   object:player];
    }
    if (playbackTimeAction) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:playbackTimeAction
                                                     name:SGPlayerPlaybackTimeDidChangeNotificationName
                                                   object:player];
    }
    if (loadedAction) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:loadedAction
                                                     name:SGPlayerLoadedTimeDidChangeNotificationName
                                                   object:player];
    }
    if (errorAction) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:errorAction
                                                     name:SGPlayerDidErrorNotificationName
                                                   object:player];
    }
}

- (void)sg_removeNotificationForPlayer:(id)player
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SGPlayerPlaybackStateDidChangeNotificationName object:player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SGPlayerLoadStateDidChangeNotificationName object:player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SGPlayerPlaybackTimeDidChangeNotificationName object:player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SGPlayerLoadedTimeDidChangeNotificationName object:player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SGPlayerDidErrorNotificationName object:player];
}

@end


#pragma mark - Action Models

@implementation NSDictionary (SGPlayerModel)

- (SGPlaybackStateModel *)sg_playbackStateModel
{
    return [self objectForKey:SGPlayerNotificationUserInfoObjectKey];
}

- (SGLoadedStateModel *)sg_loadedStateModel
{
    return [self objectForKey:SGPlayerNotificationUserInfoObjectKey];
}

- (SGTimeModel *)sg_playbackTimeModel
{
    return [self objectForKey:SGPlayerNotificationUserInfoObjectKey];
}

- (SGTimeModel *)sg_loadedTimeModel
{
    return [self objectForKey:SGPlayerNotificationUserInfoObjectKey];
}

- (NSError *)sg_error
{
    return [self objectForKey:SGPlayerNotificationUserInfoObjectKey];
}

@end

@implementation SGPlaybackStateModel

@end

@implementation SGLoadedStateModel

@end

@implementation SGTimeModel

- (NSTimeInterval)percent
{
    return self.current / self.duration;
}

@end
