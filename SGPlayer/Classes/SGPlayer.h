//
//  SGPlayer.h
//  SGPlayer
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#if __has_include(<SGPlayer/SGPlayer.h>)
FOUNDATION_EXPORT double SGPlayerVersionNumber;
FOUNDATION_EXPORT const unsigned char SGPlayerVersionString[];
#import <SGPlayer/SGDefines.h>
#import <SGPlayer/SGFFDefines.h>
#import <SGPlayer/SGAsset.h>
#import <SGPlayer/SGURLAsset.h>
#import <SGPlayer/SGConcatAsset.h>
#import <SGPlayer/SGFrame.h>
#import <SGPlayer/SGAudioFrame.h>
#import <SGPlayer/SGVideoFrame.h>
#import <SGPlayer/SGVRViewport.h>
#else
#import "SGDefines.h"
#import "SGFFDefines.h"
#import "SGAsset.h"
#import "SGURLAsset.h"
#import "SGConcatAsset.h"
#import "SGFrame.h"
#import "SGAudioFrame.h"
#import "SGVideoFrame.h"
#import "SGVRViewport.h"
#endif

#pragma mark - SGPlayer

@interface SGPlayer : NSObject

@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, strong) id object;

@end

#pragma mark - Asset

@interface SGPlayer (Asset)

@property (nonatomic, strong, readonly) SGAsset * asset;

- (void)replaceWithURL:(NSURL *)URL;
- (void)replaceWithAsset:(SGAsset *)asset;

@end

#pragma mark - State

@interface SGPlayer (State)

@property (nonatomic, strong, readonly) NSError * error;
@property (nonatomic, assign, readonly) SGPlaybackState state;
@property (nonatomic, assign, readonly) SGLoadingState loadingState;

@end

#pragma mark - Timing

@interface SGPlayer (Timing)

@property (nonatomic, assign, readonly) CMTime time;
@property (nonatomic, assign, readonly) CMTime loadedTime;
@property (nonatomic, assign, readonly) CMTime duration;

@end

#pragma mark - Playback

@interface SGPlayer (Playback)

/**
 *  Default value is (1, 1).
 */
@property (nonatomic, assign) CMTime rate;

- (void)play;
- (void)pause;
- (void)stop;

- (BOOL)seekable;
- (BOOL)seekableToTime:(CMTime)time;

- (BOOL)seekToTime:(CMTime)time;
- (BOOL)seekToTime:(CMTime)time completionHandler:(void(^)(BOOL success, CMTime time))completionHandler;

@end

#pragma mark - Audio

@interface SGPlayer (Audio)

/**
 *  Default value is 1.0.
 */
@property (nonatomic, assign) float volume;

@end

#pragma mark - Video

@interface SGPlayer (Video)

/**
 *  The instance of View for display visula output.
 */
@property (nonatomic, strong) UIView * view;

/**
 *  Default value is SGDisplayModePlane.
 */
@property (nonatomic, assign) SGDisplayMode displayMode;

/**
 *  VR Viewport.
 */
@property (nonatomic, strong) SGVRViewport * viewport;

/**
 *  Callback on main thread.
 */
@property (nonatomic, copy) void (^renderCallback)(SGVideoFrame * frame);

@end

#pragma mark - Delegate

@protocol SGPlayerDelegate <NSObject>

- (void)playerDidChangeState:(SGPlayer *)player;
- (void)playerDidChangeLoadingState:(SGPlayer *)player;
- (void)playerDidChangeTimingInfo:(SGPlayer *)player;

@end

@interface SGPlayer (Delegate)

@property (nonatomic, weak) id <SGPlayerDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;       // Default value is nil.
@property (nonatomic, assign) BOOL asynchronous;                    // Default value is YES.

@end
