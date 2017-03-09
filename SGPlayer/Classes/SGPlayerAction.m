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

@implementation SGPlayer (SGPlayerAction)

- (void)registerPlayerNotificationTarget:(id)target
                             stateAction:(nullable SEL)stateAction
                          progressAction:(nullable SEL)progressAction
                          playableAction:(nullable SEL)playableAction
{
    [self registerPlayerNotificationTarget:target
                               stateAction:stateAction
                            progressAction:progressAction
                            playableAction:playableAction
                               errorAction:nil];
}

- (void)registerPlayerNotificationTarget:(id)target
                             stateAction:(nullable SEL)stateAction
                          progressAction:(nullable SEL)progressAction
                          playableAction:(nullable SEL)playableAction
                             errorAction:(nullable SEL)errorAction
{
    if (!target) return;
    [self removePlayerNotificationTarget:target];
    
    if (stateAction) {
        [[NSNotificationCenter defaultCenter] addObserver:target selector:stateAction name:SGPlayerStateChangeNotificationName object:self];
    }
    if (progressAction) {
        [[NSNotificationCenter defaultCenter] addObserver:target selector:progressAction name:SGPlayerProgressChangeNotificationName object:self];
    }
    if (playableAction) {
        [[NSNotificationCenter defaultCenter] addObserver:target selector:playableAction name:SGPlayerPlayableChangeNotificationName object:self];
    }
    if (errorAction) {
        [[NSNotificationCenter defaultCenter] addObserver:target selector:errorAction name:SGPlayerErrorNotificationName object:self];
    }
}

- (void)removePlayerNotificationTarget:(id)target
{
    [[NSNotificationCenter defaultCenter] removeObserver:target name:SGPlayerStateChangeNotificationName object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:target name:SGPlayerProgressChangeNotificationName object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:target name:SGPlayerPlayableChangeNotificationName object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:target name:SGPlayerErrorNotificationName object:self];
}

@end


#pragma mark - SGPlayer Action Models

@implementation SGModel

+ (SGState *)stateFromUserInfo:(NSDictionary *)userInfo
{
    SGState * state = [[SGState alloc] init];
    state.previous = [[userInfo objectForKey:SGPlayerStatePreviousKey] integerValue];
    state.current = [[userInfo objectForKey:SGPlayerStateCurrentKey] integerValue];
    return state;
}

+ (SGProgress *)progressFromUserInfo:(NSDictionary *)userInfo
{
    SGProgress * progress = [[SGProgress alloc] init];
    progress.percent = [[userInfo objectForKey:SGPlayerProgressPercentKey] doubleValue];
    progress.current = [[userInfo objectForKey:SGPlayerProgressCurrentKey] doubleValue];
    progress.total = [[userInfo objectForKey:SGPlayerProgressTotalKey] doubleValue];
    return progress;
}

+ (SGPlayable *)playableFromUserInfo:(NSDictionary *)userInfo
{
    SGPlayable * playable = [[SGPlayable alloc] init];
    playable.percent = [[userInfo objectForKey:SGPlayerPlayablePercentKey] doubleValue];
    playable.current = [[userInfo objectForKey:SGPlayerPlayableCurrentKey] doubleValue];
    playable.total = [[userInfo objectForKey:SGPlayerPlayableTotalKey] doubleValue];
    return playable;
}

+ (SGError *)errorFromUserInfo:(NSDictionary *)userInfo
{
    SGError * error = [userInfo objectForKey:SGPlayerErrorKey];
    if ([error isKindOfClass:[SGError class]]) {
        return error;
    } else if ([error isKindOfClass:[NSError class]]) {
        SGError * obj = [[SGError alloc] init];
        obj.error = (NSError *)error;
        return obj;
    } else {
        SGError * obj = [[SGError alloc] init];
        obj.error = [NSError errorWithDomain:@"SGPlayer error" code:-1 userInfo:nil];
        return obj;
    }
}

@end

@implementation SGState
@end

@implementation SGProgress
@end

@implementation SGPlayable
@end

@implementation SGErrorEvent
@end

@implementation SGError
@end
