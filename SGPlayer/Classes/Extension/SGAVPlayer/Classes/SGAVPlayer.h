//
//  SGAVPlayer.h
//  SGAVPlayer
//
//  Created by Single on 16/6/28.
//  Copyright © 2016年 single. All rights reserved.
//

#import <UIKit/UIKit.h>

#if __has_include(<SGAVPlayer/SGAVPlayer.h>)
FOUNDATION_EXPORT double SGAVPlayerVersionNumber;
FOUNDATION_EXPORT const unsigned char SGAVPlayerVersionString[];
#import <SGAVPlayer/SGPlayerDefines.h>
#import <SGAVPlayer/SGPlayerAction.h>
#import <SGAVPlayer/SGPlatform.h>
#else
#import "SGPlayerDefines.h"
#import "SGPlayerAction.h"
#import "SGPlatform.h"
#endif


@interface SGAVPlayer : NSObject

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
