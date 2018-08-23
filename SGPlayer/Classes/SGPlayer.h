//
//  SGFFPlayer.h
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
#else
#import "SGDefines.h"
#import "SGFFDefines.h"
#import "SGAsset.h"
#import "SGURLAsset.h"
#import "SGConcatAsset.h"
#import "SGFrame.h"
#import "SGAudioFrame.h"
#import "SGVideoFrame.h"
#endif

@class SGPlayer;

@protocol SGFFPlayerDelegate <NSObject>

- (void)playerDidChangeState:(SGPlayer *)player;
- (void)playerDidChangeLoadingState:(SGPlayer *)player;
- (void)playerDidChangeTimingInfo:(SGPlayer *)player;

@end

@interface SGPlayer : NSObject

@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, strong) id object;

@property (nonatomic, weak) id <SGFFPlayerDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;       // Default is nil.
@property (nonatomic, assign) BOOL asynchronous;                    // Default is YES.

@property (nonatomic, strong, readonly) SGAsset * asset;

- (void)replaceWithURL:(NSURL *)URL;
- (void)replaceWithAsset:(SGAsset *)asset;

@property (nonatomic, strong, readonly) NSError * error;
@property (nonatomic, assign, readonly) SGPlaybackState state;
@property (nonatomic, assign, readonly) SGLoadingState loadingState;
@property (nonatomic, assign, readonly) CMTime time;
@property (nonatomic, assign, readonly) CMTime loadedTime;
@property (nonatomic, assign, readonly) CMTime duration;

@property (nonatomic, strong) UIView * view;
@property (nonatomic, assign) SGDisplayMode displayMode;                        // Default is SGDisplayModePlane.
@property (nonatomic, copy) void (^renderCallback)(SGVideoFrame * frame);       // Callback on main thread.

@property (nonatomic, assign) float volume;     // Default is 1.
@property (nonatomic, assign) CMTime rate;      // Default is (1, 1).

- (void)play;
- (void)pause;
- (void)stop;

- (BOOL)seekable;
- (BOOL)seekableToTime:(CMTime)time;

- (BOOL)seekToTime:(CMTime)time;
- (BOOL)seekToTime:(CMTime)time completionHandler:(void(^)(BOOL success, CMTime time))completionHandler;

@end
