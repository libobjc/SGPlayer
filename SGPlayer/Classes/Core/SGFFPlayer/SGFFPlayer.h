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

@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, strong) id object;

@property (nonatomic, weak) id <SGFFPlayerDelegate> delegate;

@property (nonatomic, copy, readonly) NSURL * URL;
- (void)replaceWithURL:(NSURL *)URL;

@property (nonatomic, assign, readonly) SGPlayerPlaybackState playbackState;
@property (nonatomic, assign, readonly) SGPlayerLoadingState loadingState;

@property (nonatomic, assign, readonly) CMTime playbackTime;
@property (nonatomic, assign, readonly) CMTime loadedTime;

@property (nonatomic, assign, readonly) CMTime duration;
@property (nonatomic, copy, readonly) NSError * error;

@property (nonatomic, strong, readonly) SGFFPlayerView * view;

- (void)play;
- (void)pause;
- (void)stop;

- (BOOL)seekable;
- (BOOL)seekToTime:(CMTime)time;
- (BOOL)seekToTime:(CMTime)time completionHandler:(void(^)(BOOL success))completionHandler;

@end
