//
//  SGRenderer+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/11/1.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGClock.h"

@protocol SGClockDelegate;

@interface SGClock (Internal)

@property (nonatomic, weak) id <SGClockDelegate> delegate;

@property (nonatomic, assign) CMTime rate;

- (CMTime)currentTime;

- (BOOL)open;
- (BOOL)close;
- (BOOL)flush;

- (BOOL)setAudioTime:(CMTime)time duration:(CMTime)duration;
- (BOOL)setVideoTime:(CMTime)time duration:(CMTime)duration;

- (BOOL)audioMaster;
- (BOOL)videoMaster;

@end

@protocol SGClockDelegate <NSObject>

- (void)clock:(SGClock *)clock didChcnageCurrentTime:(CMTime)currentTime;

@end
