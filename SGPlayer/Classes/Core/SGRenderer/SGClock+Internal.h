//
//  SGRenderer+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/11/1.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGClock.h"
#import "SGDefines.h"

@protocol SGClockDelegate;

@interface SGClock ()

/**
 *
 */
@property (nonatomic, weak) id<SGClockDelegate> delegate;

/**
 *
 */
@property (nonatomic) Float64 rate;

/**
 *
 */
@property (nonatomic, readonly) CMTime currentTime;

/**
 *
 */
- (void)setAudioTime:(CMTime)time running:(BOOL)running;

/**
 *
 */
- (void)setVideoTime:(CMTime)time;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (BOOL)close;

/**
 *
 */
- (BOOL)pause;

/**
 *
 */
- (BOOL)resume;

/**
 *
 */
- (BOOL)flush;

@end

@protocol SGClockDelegate <NSObject>

/**
 *
 */
- (void)clock:(SGClock *)clock didChangeCurrentTime:(CMTime)currentTime;

@end
