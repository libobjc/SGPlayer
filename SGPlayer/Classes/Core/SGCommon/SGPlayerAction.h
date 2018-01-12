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

NS_ASSUME_NONNULL_BEGIN

// extern
#if defined(__cplusplus)
#define SGPLAYER_EXTERN extern "C"
#else
#define SGPLAYER_EXTERN extern
#endif


// notification name
SGPLAYER_EXTERN NSString * const SGPlayerPlaybackStateDidChangeNotificationName;     // player state change
SGPLAYER_EXTERN NSString * const SGPlayerLoadStateDidChangeNotificationName;     // player state change
SGPLAYER_EXTERN NSString * const SGPlayerCurrentTimeDidChangeNotificationName;  // player play progress change
SGPLAYER_EXTERN NSString * const SGPlayerLoadedTimeDidChangeNotificationName;   // player playable progress change
SGPLAYER_EXTERN NSString * const SGPlayerDidErrorNotificationName;                   // player error

// notification userinfo key
SGPLAYER_EXTERN NSString * const SGPlayerNotificationUserInfoObjectKey;    // state


#pragma mark - SGPlayer Action Category

@interface NSObject (SGPlayerAction)

- (void)sg_registerNotificationForPlayer:(id)player
                     playbackStateAction:(SEL)playbackStateAction
                         loadStateAction:(SEL)loadStateAction
                       currentTimeAction:(SEL)currentTimeAction
                            loadedAction:(SEL)loadedAction
                             errorAction:(SEL)errorAction;

- (void)sg_removeNotificationForPlayer:(id)player;

@end


#pragma mark - SGPlayer Action Models

@interface NSDictionary (SGPlayerModel)

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

NS_ASSUME_NONNULL_END
