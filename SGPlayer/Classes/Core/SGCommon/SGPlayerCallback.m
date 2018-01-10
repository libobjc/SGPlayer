//
//  SGPlayerCallback.m
//  SGPlayer
//
//  Created by Single on 2018/1/9.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPlayerCallback.h"

@implementation SGPlayerCallback

+ (void)callbackForPlaybackState:(id)player current:(SGPlayerPlaybackState)current previous:(SGPlayerPlaybackState)previous
{
    if (player == nil) {
        return;
    }
    SGPlaybackStateModel * model = [[SGPlaybackStateModel alloc] init];
    model.current = current;
    model.previous = previous;
    [self callback:SGPlayerPlaybackStateDidChangeNotificationName object:player userInfo:@{SGPlayerNotificationUserInfoObjectKey : model}];
}

+ (void)callbackForLoadState:(id)player current:(SGPlayerLoadState)current previous:(SGPlayerLoadState)previous
{
    if (player == nil) {
        return;
    }
    SGLoadedStateModel * model = [[SGLoadedStateModel alloc] init];
    model.current = current;
    model.previous = previous;
    [self callback:SGPlayerLoadStateDidChangeNotificationName object:player userInfo:@{SGPlayerNotificationUserInfoObjectKey : model}];
}

+ (void)callbackForPlaybackTime:(id)player current:(NSTimeInterval)current duration:(NSTimeInterval)duration
{
    if (player == nil) {
        return;
    }
    SGTimeModel * model = [[SGTimeModel alloc] init];
    model.current = current;
    model.duration = duration;
    [self callback:SGPlayerPlaybackTimeDidChangeNotificationName object:player userInfo:@{SGPlayerNotificationUserInfoObjectKey : model}];
}

+ (void)callbackForLoadedTime:(id)player current:(NSTimeInterval)current duration:(NSTimeInterval)duration
{
    if (player == nil) {
        return;
    }
    SGTimeModel * model = [[SGTimeModel alloc] init];
    model.current = current;
    model.duration = duration;
    [self callback:SGPlayerLoadedTimeDidChangeNotificationName object:player userInfo:@{SGPlayerNotificationUserInfoObjectKey : model}];
}

+ (void)callbackForError:(id)player error:(NSError *)error
{
    if (error == nil) {
        return;
    }
    [self callback:SGPlayerDidErrorNotificationName object:player userInfo:@{SGPlayerNotificationUserInfoObjectKey : error}];
}

+ (void)callback:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:object userInfo:userInfo];
    });
}

@end
