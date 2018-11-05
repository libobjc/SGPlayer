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
#import <SGPlayer/SGAsset.h>
#import <SGPlayer/SGURLAsset.h>
#import <SGPlayer/SGPlayerItem.h>
#import <SGPlayer/SGConfiguration.h>
#import <SGPlayer/SGFrame.h>
#import <SGPlayer/SGAudioFrame.h>
#import <SGPlayer/SGVideoFrame.h>
#import <SGPlayer/SGClock.h>
#import <SGPlayer/SGAudioRenderer.h>
#import <SGPlayer/SGVideoRenderer.h>
#import <SGPlayer/SGVRViewport.h>
#import <SGPlayer/SGCapacity.h>
#import <SGPlayer/SGObjectPool.h>
#import <SGPlayer/SGObjectQueue.h>
#import <SGPlayer/SGPLFTargets.h>
#import <SGPlayer/SGPLFObject.h>
#import <SGPlayer/SGPLFImage.h>
#import <SGPlayer/SGPLFColor.h>
#import <SGPlayer/SGPLFView.h>

#endif

#pragma mark - SGPlayer

@interface SGPlayer : NSObject

@property (nonatomic) NSInteger tag;
@property (nonatomic, weak) id object;

- (SGPlayerStatus)status;
- (NSError *)error;

@end

#pragma mark - Item

@interface SGPlayer (Item)

- (SGPlayerItem *)currentItem;
- (CMTime)duration;

- (BOOL)replaceWithURL:(NSURL *)URL;
- (BOOL)replaceWithAsset:(SGAsset *)asset;
- (BOOL)replaceWithPlayerItem:(SGPlayerItem *)item;

- (void)waitUntilReady;

- (BOOL)stop;

@end

#pragma mark - Prepare

@interface SGPlayer (Prepare)

@end

#pragma mark - Playback

@interface SGPlayer (Playback)

- (SGPlaybackState)playbackState;
- (CMTime)currentTime;

@property (nonatomic, assign) CMTime rate;

- (BOOL)play;
- (BOOL)pause;

- (BOOL)seekable;
- (BOOL)seekToTime:(CMTime)time result:(SGSeekResultBlock)result;

@end

#pragma mark - Loading

@interface SGPlayer (Loading)

- (SGLoadingState)loadingState;
- (BOOL)loadedTime:(CMTime *)loadedTime loadedDuration:(CMTime *)loadedDuration;

@end

#pragma mark - Renderer

@interface SGPlayer (Renderer)

- (SGClock *)clock;
- (SGAudioRenderer *)audioRenderer;
- (SGVideoRenderer *)videoRenderer;

@end

#pragma mark - Delegate

@protocol SGPlayerDelegate;

@interface SGPlayer (Delegate)

@property (nonatomic, weak) id <SGPlayerDelegate> delegate;
@property (nonatomic, strong) NSOperationQueue * delegateQueue;

@end

@protocol SGPlayerDelegate <NSObject>

@optional
- (void)player:(SGPlayer *)player didChangeStatus:(SGPlayerStatus)status;
- (void)player:(SGPlayer *)player didChangePlaybackState:(SGPlaybackState)playbackState;
- (void)player:(SGPlayer *)player didChangeLoadingState:(SGLoadingState)loadingState;
- (void)player:(SGPlayer *)player didChangeCurrentTime:(CMTime)currentTime duration:(CMTime)duration;
- (void)player:(SGPlayer *)player didChangeLoadedTime:(CMTime)loadedTime loadedDuuration:(CMTime)loadedDuuration;

@end
