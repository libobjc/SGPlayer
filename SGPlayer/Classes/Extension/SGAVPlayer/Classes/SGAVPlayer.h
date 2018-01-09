//
//  SGAVPlayer.h
//  SGAVPlayer
//
//  Created by Single on 16/6/28.
//  Copyright © 2016年 single. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SGPlayerAction.h"

@interface SGAVPlayer : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)player;

@property (nonatomic, copy, readonly) NSURL * contentURL;
- (void)replaceVideoWithURL:(NSURL *)contentURL;

@property (nonatomic, strong, readonly) NSError * error;

@property (nonatomic, strong, readonly) UIView * view;

@property (nonatomic, assign, readonly) SGPlayerState state;
@property (nonatomic, assign, readonly) NSTimeInterval progress;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval playableTime;

@property (nonatomic, assign) SGPlayerBackgroundMode backgroundMode;

- (void)play;
- (void)pause;
- (void)stop;

- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time completeHandler:(void(^)(BOOL finished))completeHandler;

@end
