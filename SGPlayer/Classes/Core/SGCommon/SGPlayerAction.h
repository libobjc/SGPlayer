//
//  SGPlayerAction.h
//  SGPlayer
//
//  Created by Single on 2017/2/13.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPlayerDefines.h"

@class SGStateModel;
@class SGTimeModel;

NS_ASSUME_NONNULL_BEGIN

// extern
#if defined(__cplusplus)
#define SGPLAYER_EXTERN extern "C"
#else
#define SGPLAYER_EXTERN extern
#endif

// notification name
SGPLAYER_EXTERN NSString * const SGPlayerErrorNotificationName;             // player error
SGPLAYER_EXTERN NSString * const SGPlayerStateChangeNotificationName;       // player state change
SGPLAYER_EXTERN NSString * const SGPlayerProgressChangeNotificationName;    // player play progress change
SGPLAYER_EXTERN NSString * const SGPlayerPlayableChangeNotificationName;    // player playable progress change

// notification userinfo key
SGPLAYER_EXTERN NSString * const SGPlayerErrorKey;              // error

SGPLAYER_EXTERN NSString * const SGPlayerStatePreviousKey;      // state
SGPLAYER_EXTERN NSString * const SGPlayerStateCurrentKey;       // state

SGPLAYER_EXTERN NSString * const SGPlayerProgressPercentKey;    // progress
SGPLAYER_EXTERN NSString * const SGPlayerProgressCurrentKey;    // progress
SGPLAYER_EXTERN NSString * const SGPlayerProgressTotalKey;      // progress

SGPLAYER_EXTERN NSString * const SGPlayerPlayablePercentKey;    // playable
SGPLAYER_EXTERN NSString * const SGPlayerPlayableCurrentKey;    // playable
SGPLAYER_EXTERN NSString * const SGPlayerPlayableTotalKey;      // playable


#pragma mark - SGPlayer Action Category

@interface NSObject (SGPlayerAction)

- (void)sg_registerNotificationForPlayer:(id)player
                             stateAction:(nullable SEL)stateAction
                          progressAction:(nullable SEL)progressAction
                          playableAction:(nullable SEL)playableAction
                             errorAction:(nullable SEL)errorAction;

- (void)sg_removeNotificationForPlayer:(id)player;

@end


#pragma mark - SGPlayer Action Models

@interface NSDictionary (SGPlayerModel)

- (SGStateModel *)sg_stateModel;
- (SGTimeModel *)sg_playbackTimeModel;
- (SGTimeModel *)sg_loadedTimeModel;
- (NSError *)sg_error;

@end

@interface SGStateModel : NSObject
@property (nonatomic, assign) SGPlayerState previous;
@property (nonatomic, assign) SGPlayerState current;
@end

@interface SGTimeModel : NSObject
@property (nonatomic, assign) NSTimeInterval percent;
@property (nonatomic, assign) NSTimeInterval current;
@property (nonatomic, assign) NSTimeInterval total;
@end

NS_ASSUME_NONNULL_END
