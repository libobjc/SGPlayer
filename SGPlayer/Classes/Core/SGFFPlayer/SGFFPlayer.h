//
//  SGFFPlayer.h
//  SGPlayer
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "SGPlayerDefines.h"
#import "SGFFPlayerView.h"

@class SGFFPlayer;

@protocol SGFFPlayerDelegate <NSObject>

- (void)playerDidChangePlaybackState:(SGFFPlayer *)player;
- (void)playerDidChangePlaybackTime:(SGFFPlayer *)player;
- (void)playerDidChangeLoadingState:(SGFFPlayer *)player;
- (void)playerDidChangeLoadedTime:(SGFFPlayer *)player;

@end

@interface SGFFPlayer : NSObject

@property (nonatomic, assign, readonly) NSInteger tag;

@property (nonatomic, weak) id <SGFFPlayerDelegate> delegate;

@property (nonatomic, copy, readonly) NSURL * contentURL;
- (void)replaceWithContentURL:(NSURL *)contentURL;

@property (nonatomic, assign, readonly) SGPlayerPlaybackState playbackState;
@property (nonatomic, assign, readonly) SGPlayerLoadingState loadingState;

@property (nonatomic, assign, readonly) CMTime playbackTime;
@property (nonatomic, assign, readonly) CMTime loadedTime;

@property (nonatomic, assign, readonly) CMTime duration;
@property (nonatomic, copy, readonly) NSError * error;

@property (nonatomic, strong, readonly) SGFFPlayerView * view;
@property (nonatomic, assign) SGPlayerBackgroundMode backgroundMode;

- (void)play;
- (void)pause;
- (void)stop;
- (void)interrupt;

- (BOOL)seekable;
- (void)seekToTime:(CMTime)time;
- (void)seekToTime:(CMTime)time completionHandler:(void(^)(BOOL finished))completionHandler;

@end
