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
#import <SGPlayer/SGFFDefines.h>
#import <SGPlayer/SGAsset.h>
#import <SGPlayer/SGURLAsset.h>
#import <SGPlayer/SGConcatAsset.h>
#import <SGPlayer/SGFrame.h>
#import <SGPlayer/SGAudioFrame.h>
#import <SGPlayer/SGVideoFrame.h>
#import <SGPlayer/SGVRViewport.h>
#import <SGPlayer/SGTime.h>
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
#import "SGTime.h"
#endif

#pragma mark - SGPlayer

@interface SGPlayer : NSObject

@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, strong) id object;

@end

#pragma mark - Asset

@interface SGPlayer (Asset)

- (SGAsset *)asset;

- (NSError *)error;
- (CMTime)duration;

- (BOOL)replaceWithURL:(NSURL *)URL;
- (BOOL)replaceWithAsset:(SGAsset *)asset;

@end

#pragma mark - Prepare

@interface SGPlayer (Prepare)

- (SGPrepareState)prepareState;

- (void)waitUntilFinishedPrepare;

@end

#pragma mark - Playback

@interface SGPlayer (Playback)

- (SGPlaybackState)playbackState;
- (CMTime)playbackTime;

/**
 *  Default value is (1, 1).
 */
@property (nonatomic, assign) CMTime rate;

- (BOOL)play;
- (BOOL)pause;
- (BOOL)stop;

- (BOOL)seeking;

- (BOOL)seekable;
- (BOOL)seekableToTime:(CMTime)time;

- (BOOL)seekToTime:(CMTime)time;
- (BOOL)seekToTime:(CMTime)time completionHandler:(void(^)(BOOL success, CMTime time))completionHandler;

@end

#pragma mark - Loading

@interface SGPlayer (Loading)

- (SGLoadingState)loadingState;
- (CMTime)loadedTime;

@end

#pragma mark - Audio

@interface SGPlayer (Audio)

/**
 *  Default value is 1.0.
 */
@property (nonatomic, assign) float volume;

/**
 *  Default value is (1, 20).
 */
@property (nonatomic, assign) CMTime deviceDelay;

@end

#pragma mark - Video

@interface SGPlayer (Video)

/**
 *  The instance of View for display visula output.
 */
@property (nonatomic, strong) UIView * view;

/**
 *  Default value is SGScalingModeResizeAspect.
 */
@property (nonatomic, assign) SGScalingMode scalingMode;

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
@property (nonatomic, copy) void (^displayCallback)(SGVideoFrame * frame);

/**
 *  nullable.
 */
- (UIImage *)originalImage;

/**
 *  Must be called on the main thread.
 *  nullable.
 */
- (UIImage *)snapshot;

@end

#pragma mark - Track

@interface SGPlayer (Track)

@end

#pragma mark - FormatContext

@interface SGPlayer (FormatContext)

@property (nonatomic, copy) NSDictionary * formatContextOptions;

@end

#pragma mark - CodecContext

@interface SGPlayer (CodecContext)

/**
 *  Default value is nil.
 */
@property (nonatomic, copy) NSDictionary * codecContextOptions;

/**
 *  Default value is YES.
 */
@property (nonatomic, assign) BOOL threadsAuto;

/**
 *  Default value is YES.
 */
@property (nonatomic, assign) BOOL refcountedFrames;

/**
 *  Default value is YES.
 */
@property (nonatomic, assign) BOOL hardwareDecodeH264;

/**
 *  Default value is YES.
 */
@property (nonatomic, assign) BOOL hardwareDecodeH265;

@end

#pragma mark - Delegate

@protocol SGPlayerDelegate <NSObject>

- (void)playerDidChangePrepareState:(SGPlayer *)player;
- (void)playerDidChangePlaybackState:(SGPlayer *)player;
- (void)playerDidChangeLoadingState:(SGPlayer *)player;
- (void)playerDidChangeTimingInfo:(SGPlayer *)player;
- (void)playerDidFailed:(SGPlayer *)player;

@end

@interface SGPlayer (Delegate)

@property (nonatomic, weak) id <SGPlayerDelegate> delegate;
@property (nonatomic, strong) NSOperationQueue * delegateQueue;

@end
