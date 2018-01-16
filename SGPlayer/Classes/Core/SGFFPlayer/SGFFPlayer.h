//
//  SGFFPlayer.h
//  SGPlayer
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SGPlayerDefines.h"
#import "SGPlayerAction.h"
#import "SGPlatform.h"


@interface SGFFPlayer : NSObject <SGPlayer>

@property (nonatomic, assign, readonly) NSInteger tag;

@property (nonatomic, copy, readonly) NSURL * contentURL;
- (void)replaceWithContentURL:(NSURL *)contentURL;

@property (nonatomic, assign, readonly) SGPlayerPlaybackState playbackState;
@property (nonatomic, assign, readonly) SGPlayerLoadState loadState;

@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval currentTime;
@property (nonatomic, assign, readonly) NSTimeInterval loadedTime;
@property (nonatomic, copy, readonly) NSError * error;

@property (nonatomic, strong, readonly) SGPLFView * view;
@property (nonatomic, assign) SGPlayerBackgroundMode backgroundMode;
@property (nonatomic, assign) NSTimeInterval minimumPlayableDuration;       // Default is 2s.

- (void)play;
- (void)pause;
- (void)stop;

- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time completionHandler:(void(^)(BOOL finished))completionHandler;

@end
