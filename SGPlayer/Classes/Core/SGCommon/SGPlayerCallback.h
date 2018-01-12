//
//  SGPlayerCallback.h
//  SGPlayer
//
//  Created by Single on 2018/1/9.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPlayerAction.h"

@interface SGPlayerCallback : NSObject

+ (void)callbackForPlaybackState:(id<SGPlayer>)player
                         current:(SGPlayerPlaybackState)current
                        previous:(SGPlayerPlaybackState)previous;

+ (void)callbackForLoadState:(id<SGPlayer>)player
                     current:(SGPlayerLoadState)current
                    previous:(SGPlayerLoadState)previous;

+ (void)callbackForCurrentTime:(id<SGPlayer>)player
                       current:(NSTimeInterval)current
                      duration:(NSTimeInterval)duration;

+ (void)callbackForLoadedTime:(id<SGPlayer>)player
                      current:(NSTimeInterval)current
                     duration:(NSTimeInterval)duration;

+ (void)callbackForError:(id<SGPlayer>)player
                   error:(NSError *)error;

@end
