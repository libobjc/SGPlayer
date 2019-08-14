//
//  SGPlayer.h
//  SGPlayer
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<SGPlayer/SGPlayer.h>)

FOUNDATION_EXPORT double SGPlayerVersionNumber;
FOUNDATION_EXPORT const unsigned char SGPlayerVersionString[];

#import <SGPlayer/SGDefines.h>
#import <SGPlayer/SGTime.h>
#import <SGPlayer/SGTrack.h>
#import <SGPlayer/SGMutableTrack.h>
#import <SGPlayer/SGAsset.h>
#import <SGPlayer/SGURLAsset.h>
#import <SGPlayer/SGMutableAsset.h>
#import <SGPlayer/SGSegment.h>
#import <SGPlayer/SGURLSegment.h>
#import <SGPlayer/SGPaddingSegment.h>
#import <SGPlayer/SGPlayerItem.h>
#import <SGPlayer/SGFrameOutput.h>
#import <SGPlayer/SGPacketOutput.h>
#import <SGPlayer/SGOptions.h>
#import <SGPlayer/SGData.h>
#import <SGPlayer/SGFrame.h>
#import <SGPlayer/SGAudioFrame.h>
#import <SGPlayer/SGVideoFrame.h>
#import <SGPlayer/SGAudioDescriptor.h>
#import <SGPlayer/SGVideoDescriptor.h>
#import <SGPlayer/SGClock.h>
#import <SGPlayer/SGAudioRenderer.h>
#import <SGPlayer/SGVideoRenderer.h>
#import <SGPlayer/SGVRViewport.h>
#import <SGPlayer/SGCapacity.h>
#import <SGPlayer/SGPLFTargets.h>
#import <SGPlayer/SGPLFObject.h>
#import <SGPlayer/SGPLFImage.h>
#import <SGPlayer/SGPLFColor.h>
#import <SGPlayer/SGPLFView.h>

#endif

#pragma mark - SGPlayer

@interface SGPlayer : NSObject

@property (nonatomic, strong) SGOptions *options;

- (NSError *)error;
- (SGTimeInfo)timeInfo;
- (SGStateInfo)stateInfo;

- (BOOL)error:(NSError **)error timeInfo:(SGTimeInfo *)timeInfo stateInfo:(SGStateInfo *)stateInfo;

@end

#pragma mark - Item

@interface SGPlayer ()

- (SGPlayerItem *)currentItem;

@property (nonatomic, copy) void (^readyHandler)(SGPlayer *player);

- (BOOL)replaceWithURL:(NSURL *)URL;
- (BOOL)replaceWithAsset:(SGAsset *)asset;
- (BOOL)replaceWithPlayerItem:(SGPlayerItem *)item;

@end

#pragma mark - Playback

@interface SGPlayer ()

@property (nonatomic) Float64 rate;

@property (nonatomic, readonly) BOOL needsPlay;
@property (nonatomic) BOOL pausesWhenInterrupted;

- (BOOL)play;
- (BOOL)pause;

- (BOOL)seekable;
- (BOOL)seekToTime:(CMTime)time result:(SGSeekResult)result;

@end

#pragma mark - Renderer

@interface SGPlayer ()

- (SGClock *)clock;
- (SGAudioRenderer *)audioRenderer;
- (SGVideoRenderer *)videoRenderer;

@end

#pragma mark - Notification

SGPLAYER_EXTERN NSNotificationName const SGPlayerDidChangeInfosNotification;

SGPLAYER_EXTERN NSString * const SGPlayerTimeInfoUserInfoKey;
SGPLAYER_EXTERN NSString * const SGPlayerStateInfoUserInfoKey;
SGPLAYER_EXTERN NSString * const SGPlayerInfoActionUserInfoKey;

@interface SGPlayer ()

+ (SGTimeInfo)timeInfoFromUserInfo:(NSDictionary *)userInfo;
+ (SGStateInfo)stateInfoFromUserInfo:(NSDictionary *)userInfo;
+ (SGInfoAction)infoActionFromUserInfo:(NSDictionary *)userInfo;

@property (nonatomic) SGInfoAction actionMask;
@property (nonatomic) NSTimeInterval minimumTimeInfoInterval;
@property (nonatomic, strong) NSOperationQueue *notificationQueue;

@end
