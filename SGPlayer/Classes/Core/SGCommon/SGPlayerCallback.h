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

+ (void)callbackForPlaybackState:(id)player current:(SGPlayerPlaybackState)current previous:(SGPlayerPlaybackState)previous;
+ (void)callbackForLoadState:(id)player current:(SGPlayerLoadState)current previous:(SGPlayerLoadState)previous;
+ (void)callbackForPlaybackTime:(id)player current:(NSTimeInterval)current duration:(NSTimeInterval)duration;
+ (void)callbackForLoadedTime:(id)player current:(NSTimeInterval)current duration:(NSTimeInterval)duration;
+ (void)callbackForError:(id)player error:(NSError *)error;

@end
