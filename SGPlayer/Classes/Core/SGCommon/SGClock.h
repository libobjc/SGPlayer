//
//  SGClock.h
//  SGPlayer
//
//  Created by Single on 2018/6/14.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTime.h"

@protocol SGClockDelegate;

@interface SGClock : NSObject

@property (nonatomic, weak) id <SGClockDelegate> delegate;

@property (nonatomic, assign) CMTime rate;

- (CMTime)currentTime;

- (BOOL)open;
- (BOOL)close;

- (BOOL)setTime:(CMTime)time duration:(CMTime)duration;
- (BOOL)flush;

@end

@protocol SGClockDelegate <NSObject>

- (void)clock:(SGClock *)clock didChcnageCurrentTime:(CMTime)currentTime;

@end
