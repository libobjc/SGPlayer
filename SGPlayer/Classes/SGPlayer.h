//
//  SGPlayer.h
//  SGPlayer
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#if __has_include(<SGPlayer/SGPlayer.h>)
FOUNDATION_EXPORT double SGPlayerVersionNumber;
FOUNDATION_EXPORT const unsigned char SGPlayerVersionString[];
#import <SGPlayer/SGDefines.h>
#import <SGPlayer/SGAsset.h>
#import <SGPlayer/SGURLAsset.h>
#import <SGPlayer/SGPlayerItem.h>
#import <SGPlayer/SGFrame.h>
#import <SGPlayer/SGAudioFrame.h>
#import <SGPlayer/SGVideoFrame.h>
#import <SGPlayer/SGVRViewport.h>
#import <SGPlayer/SGTime.h>
#import <SGPlayer/SGDiscardFilter.h>
#import <SGPlayer/SGAudioRenderer.h>
#import <SGPlayer/SGVideoRenderer.h>
#else
#import "SGDefines.h"
#import "SGFFDefines.h"
#import "SGAsset.h"
#import "SGURLAsset.h"
#import "SGFrame.h"
#import "SGAudioFrame.h"
#import "SGVideoFrame.h"
#import "SGVRViewport.h"
#import "SGTime.h"
#import "SGDiscardFilter.h"
#endif

#pragma mark - SGPlayer

@interface SGPlayer : NSObject

@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, strong) id object;

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

- (SGAudioRenderer *)audioRenderer;
- (SGVideoRenderer *)videoRenderer;

@end

#pragma mark - Delegate

@protocol SGPlayerDelegate <NSObject>

@optional
- (void)player:(SGPlayer *)player didChangeStatus:(SGPlayerStatus)status;
- (void)player:(SGPlayer *)player didChangePlaybackState:(SGPlaybackState)playbackState;
- (void)player:(SGPlayer *)player didChangeLoadingState:(SGLoadingState)loadingState;
- (void)player:(SGPlayer *)player didChangeCurrentTime:(CMTime)currentTime;
- (void)player:(SGPlayer *)player didChangeLoadedTime:(CMTime)loadedTime loadedDuuration:(CMTime)loadedDuuration;

@end

@interface SGPlayer (Delegate)

@property (nonatomic, weak) id <SGPlayerDelegate> delegate;
@property (nonatomic, strong) NSOperationQueue * delegateQueue;

@end
