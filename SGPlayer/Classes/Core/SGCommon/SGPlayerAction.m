//
//  SGPlayerAction.m
//  SGPlayer
//
//  Created by Single on 2017/2/13.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPlayerAction.h"

// notification name
NSString * const SGPlayerErrorNotificationName = @"SGPlayerErrorNotificationName";                   // player error
NSString * const SGPlayerStateChangeNotificationName = @"SGPlayerStateChangeNotificationName";     // player state change
NSString * const SGPlayerProgressChangeNotificationName = @"SGPlayerProgressChangeNotificationName";  // player play progress change
NSString * const SGPlayerPlayableChangeNotificationName = @"SGPlayerPlayableChangeNotificationName";   // player playable progress change

// notification userinfo key
NSString * const SGPlayerErrorKey = @"error";               // error

NSString * const SGPlayerStatePreviousKey = @"previous";    // state
NSString * const SGPlayerStateCurrentKey = @"current";      // state

NSString * const SGPlayerProgressPercentKey = @"percent";   // progress
NSString * const SGPlayerProgressCurrentKey = @"current";   // progress
NSString * const SGPlayerProgressTotalKey = @"total";       // progress

NSString * const SGPlayerPlayablePercentKey = @"percent";   // playable
NSString * const SGPlayerPlayableCurrentKey = @"current";   // playable
NSString * const SGPlayerPlayableTotalKey = @"total";       // playable


#pragma mark - SGPlayer Action Category

@implementation NSObject (SGPlayerAction)

- (void)sg_registerNotificationForPlayer:(id)player
                             stateAction:(SEL)stateAction
                          progressAction:(SEL)progressAction
                          playableAction:(SEL)playableAction
                             errorAction:(SEL)errorAction
{
    [self sg_removeNotificationForPlayer:player];
    
    if (stateAction) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:stateAction
                                                     name:SGPlayerStateChangeNotificationName
                                                   object:player];
    }
    if (progressAction) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:progressAction
                                                     name:SGPlayerProgressChangeNotificationName
                                                   object:player];
    }
    if (playableAction) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:playableAction
                                                     name:SGPlayerPlayableChangeNotificationName
                                                   object:player];
    }
    if (errorAction) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:errorAction
                                                     name:SGPlayerErrorNotificationName
                                                   object:player];
    }
}

- (void)sg_removeNotificationForPlayer:(id)player
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SGPlayerStateChangeNotificationName object:player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SGPlayerProgressChangeNotificationName object:player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SGPlayerPlayableChangeNotificationName object:player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SGPlayerErrorNotificationName object:player];
}

@end


#pragma mark - Action Models

@implementation NSDictionary (SGPlayerModel)

- (SGStateModel *)sg_stateModel
{
    SGStateModel * state = [[SGStateModel alloc] init];
    state.previous = [[self objectForKey:SGPlayerStatePreviousKey] integerValue];
    state.current = [[self objectForKey:SGPlayerStateCurrentKey] integerValue];
    return state;
}

- (SGTimeModel *)sg_playbackTimeModel
{
    SGTimeModel * time = [[SGTimeModel alloc] init];
    time.percent = [[self objectForKey:SGPlayerProgressPercentKey] doubleValue];
    time.current = [[self objectForKey:SGPlayerProgressCurrentKey] doubleValue];
    time.total = [[self objectForKey:SGPlayerProgressTotalKey] doubleValue];
    return time;
}

- (SGTimeModel *)sg_loadedTimeModel
{
    SGTimeModel * time = [[SGTimeModel alloc] init];
    time.percent = [[self objectForKey:SGPlayerPlayablePercentKey] doubleValue];
    time.current = [[self objectForKey:SGPlayerPlayableCurrentKey] doubleValue];
    time.total = [[self objectForKey:SGPlayerPlayableTotalKey] doubleValue];
    return time;
}

- (NSError *)sg_error
{
    return [self objectForKey:SGPlayerErrorKey];
}

@end

@implementation SGStateModel
@end

@implementation SGTimeModel
@end
