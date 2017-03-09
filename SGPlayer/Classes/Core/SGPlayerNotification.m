//
//  SGNotification.m
//  SGPlayer
//
//  Created by Single on 16/8/15.
//  Copyright © 2016年 single. All rights reserved.
//

#import "SGPlayerNotification.h"

@implementation SGPlayerNotification

+ (void)postPlayer:(SGPlayer *)player error:(SGError *)error
{
    if (!player || !error) return;
    NSDictionary * userInfo = @{
                                SGPlayerErrorKey : error
                                };
    player.error = error;
    [self postNotificationName:SGPlayerErrorNotificationName object:player userInfo:userInfo];
}

+ (void)postPlayer:(SGPlayer *)player statePrevious:(SGPlayerState)previous current:(SGPlayerState)current
{
    if (!player) return;
    NSDictionary * userInfo = @{
                                SGPlayerStatePreviousKey : @(previous),
                                SGPlayerStateCurrentKey : @(current)
                                };
    [self postNotificationName:SGPlayerStateChangeNotificationName object:player userInfo:userInfo];
}

+ (void)postPlayer:(SGPlayer *)player progressPercent:(NSNumber *)percent current:(NSNumber *)current total:(NSNumber *)total
{
    if (!player) return;
    if (![percent isKindOfClass:[NSNumber class]]) percent = @(0);
    if (![current isKindOfClass:[NSNumber class]]) current = @(0);
    if (![total isKindOfClass:[NSNumber class]]) total = @(0);
    NSDictionary * userInfo = @{
                                SGPlayerProgressPercentKey : percent,
                                SGPlayerProgressCurrentKey : current,
                                SGPlayerProgressTotalKey : total
                                };
    [self postNotificationName:SGPlayerProgressChangeNotificationName object:player userInfo:userInfo];
}

+ (void)postPlayer:(SGPlayer *)player playablePercent:(NSNumber *)percent current:(NSNumber *)current total:(NSNumber *)total
{
    if (!player) return;
    if (![percent isKindOfClass:[NSNumber class]]) percent = @(0);
    if (![current isKindOfClass:[NSNumber class]]) current = @(0);
    if (![total isKindOfClass:[NSNumber class]]) total = @(0);
    NSDictionary * userInfo = @{
                                SGPlayerPlayablePercentKey : percent,
                                SGPlayerPlayableCurrentKey : current,
                                SGPlayerPlayableTotalKey : total,
                                };
    [self postNotificationName:SGPlayerPlayableChangeNotificationName object:player userInfo:userInfo];
}

+ (void)postNotificationName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:object userInfo:userInfo];
    });
}

@end
