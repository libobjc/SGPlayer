//
//  SGPlayer.h
//  SGPlayer
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGPlayerHeader.h"

#pragma mark - SGPlayer

@interface SGPlayer : NSObject

/**
 *
 */
@property (nonatomic, strong) SGOptions *options;

/**
 *
 */
- (BOOL)stateInfo:(SGStateInfo *)stateInfo timeInfo:(SGTimeInfo *)timeInfo error:(NSError **)error;

@end

#pragma mark - Item

@interface SGPlayer ()

/**
 *
 */
- (SGPlayerItem *)currentItem;

/**
 *
 */
@property (nonatomic, copy) SGHandler readyHandler;

/**
 *
 */
- (BOOL)replaceWithURL:(NSURL *)URL;

/**
 *
 */
- (BOOL)replaceWithAsset:(SGAsset *)asset;

/**
 *
 */
- (BOOL)replaceWithPlayerItem:(SGPlayerItem *)item;

@end

#pragma mark - Playback

@interface SGPlayer ()

/**
 *
 */
@property (nonatomic) Float64 rate;

/**
 *
 */
@property (nonatomic, readonly) BOOL wantsToPlay;

/**
 *
 */
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
@property (nonatomic) BOOL pausesWhenInterrupted;
#endif

/**
 *
 */
- (BOOL)play;

/**
 *
 */
- (BOOL)pause;

/**
 *
 */
- (BOOL)seekable;

/**
 *
 */
- (BOOL)seekToTime:(CMTime)time result:(SGSeekResult)result;

@end

#pragma mark - Renderer

@interface SGPlayer ()

/**
 *
 */
- (SGClock *)clock;

/**
 *
 */
- (SGAudioRenderer *)audioRenderer;

/**
 *
 */
- (SGVideoRenderer *)videoRenderer;

@end

#pragma mark - Notification

/**
 *
 */
SGPLAYER_EXTERN NSNotificationName const SGPlayerDidChangeInfosNotification;

/**
 *
 */
SGPLAYER_EXTERN NSString * const SGPlayerTimeInfoUserInfoKey;

/**
 *
 */
SGPLAYER_EXTERN NSString * const SGPlayerStateInfoUserInfoKey;

/**
 *
 */
SGPLAYER_EXTERN NSString * const SGPlayerInfoActionUserInfoKey;

@interface SGPlayer ()

/**
 *
 */
+ (SGTimeInfo)timeInfoFromUserInfo:(NSDictionary *)userInfo;

/**
 *
 */
+ (SGStateInfo)stateInfoFromUserInfo:(NSDictionary *)userInfo;

/**
 *
 */
+ (SGInfoAction)infoActionFromUserInfo:(NSDictionary *)userInfo;

/**
 *
 */
@property (nonatomic) SGInfoAction actionMask;

/**
 *
 */
@property (nonatomic) NSTimeInterval minimumTimeInfoInterval;

/**
 *
 */
@property (nonatomic, strong) NSOperationQueue *notificationQueue;

@end
