//
//  SGPlayerAction.h
//  SGPlayer
//
//  Created by Single on 2017/2/13.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPlayerDefines.h"

@class SGPlaybackStateModel;
@class SGLoadedStateModel;
@class SGTimeModel;


/**
 *  Notification Name
 */
SGPLAYER_EXTERN NSString * const SGPlayerPlaybackStateDidChangeNotificationName;
SGPLAYER_EXTERN NSString * const SGPlayerLoadStateDidChangeNotificationName;
SGPLAYER_EXTERN NSString * const SGPlayerCurrentTimeDidChangeNotificationName;
SGPLAYER_EXTERN NSString * const SGPlayerLoadedTimeDidChangeNotificationName;
SGPLAYER_EXTERN NSString * const SGPlayerDidErrorNotificationName;

/**
 *  Notification Userinfo Key
 */
SGPLAYER_EXTERN NSString * const SGPlayerNotificationUserInfoObjectKey;    // Common Object Key.


@interface NSObject (SGPlayerAction)

- (void)sg_registerNotificationForPlayer:(id)player
                     playbackStateAction:(SEL)playbackStateAction
                         loadStateAction:(SEL)loadStateAction
                       currentTimeAction:(SEL)currentTimeAction
                            loadedAction:(SEL)loadedAction
                             errorAction:(SEL)errorAction;

- (void)sg_removeNotificationForPlayer:(id)player;

@end


@interface NSDictionary (SGPlayerModel)

/**
 *  Objects In UserInfo
 */
- (SGPlaybackStateModel *)sg_playbackStateModel;
- (SGLoadedStateModel *)sg_loadedStateModel;
- (SGTimeModel *)sg_currentTimeModel;
- (SGTimeModel *)sg_loadedTimeModel;
- (NSError *)sg_error;

@end


@interface SGPlaybackStateModel : NSObject

@property (nonatomic, assign) SGPlayerPlaybackState previous;
@property (nonatomic, assign) SGPlayerPlaybackState current;

@end


@interface SGLoadedStateModel : NSObject

@property (nonatomic, assign) SGPlayerLoadState previous;
@property (nonatomic, assign) SGPlayerLoadState current;

@end


@interface SGTimeModel : NSObject

@property (nonatomic, assign) NSTimeInterval current;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval percent;

@end
