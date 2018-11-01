//
//  SGClock.h
//  SGPlayer
//
//  Created by Single on 2018/6/14.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTime.h"

@class SGClock;

@protocol SGClockDelegate <NSObject>

- (void)playbackClockDidChangeStartTime:(SGClock *)playbackClock;

@end

@interface SGClock : NSObject

@property (nonatomic, weak) id <SGClockDelegate> delegate;

@property (nonatomic, assign, readonly) CMTime time;
@property (nonatomic, assign, readonly) CMTime unlimitedTime;
@property (nonatomic, assign, readonly) CMTime keyTime;
@property (nonatomic, assign, readonly) CMTime startTime;

- (BOOL)open;
- (BOOL)close;

- (void)updateKeyTime:(CMTime)time duration:(CMTime)duration rate:(CMTime)rate;
- (void)flush;

@end
