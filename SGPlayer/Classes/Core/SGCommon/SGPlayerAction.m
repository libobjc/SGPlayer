//
//  SGPlayerAction.m
//  SGPlayer
//
//  Created by Single on 2017/2/13.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPlayerAction.h"


NSString * const SGPlayerPlaybackStateDidChangeNotificationName = @"SGPlayerPlaybackStateDidChangeNotificationName";
NSString * const SGPlayerLoadStateDidChangeNotificationName     = @"SGPlayerLoadStateDidChangeNotificationName";
NSString * const SGPlayerCurrentTimeDidChangeNotificationName   = @"SGPlayerCurrentTimeDidChangeNotificationName";
NSString * const SGPlayerLoadedTimeDidChangeNotificationName    = @"SGPlayerLoadedTimeDidChangeNotificationName";
NSString * const SGPlayerDidErrorNotificationName               = @"SGPlayerDidErrorNotificationName";

NSString * const SGPlayerNotificationUserInfoObjectKey          = @"SGPlayerNotificationUserInfoObjectKey";


@implementation NSObject (SGPlayerAction)

- (void)sg_registerNotificationForPlayer:(id)player
                     playbackStateAction:(SEL)playbackStateAction
                         loadStateAction:(SEL)loadStateAction
                       currentTimeAction:(SEL)currentTimeAction
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
    if (currentTimeAction) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:currentTimeAction
                                                     name:SGPlayerCurrentTimeDidChangeNotificationName
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SGPlayerCurrentTimeDidChangeNotificationName object:player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SGPlayerLoadedTimeDidChangeNotificationName object:player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SGPlayerDidErrorNotificationName object:player];
}

@end


@implementation NSDictionary (SGPlayerModel)

- (SGPlaybackStateModel *)sg_playbackStateModel
{
    return [self objectForKey:SGPlayerNotificationUserInfoObjectKey];
}

- (SGLoadedStateModel *)sg_loadedStateModel
{
    return [self objectForKey:SGPlayerNotificationUserInfoObjectKey];
}

- (SGTimeModel *)sg_currentTimeModel
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
