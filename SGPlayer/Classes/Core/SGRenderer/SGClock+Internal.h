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

@interface SGClock (Internal)

@property (nonatomic, weak) id<SGClockDelegate> delegate;

@property (nonatomic) CMTime rate;

- (CMTime)currentTime;

- (BOOL)open;
- (BOOL)close;
- (BOOL)pause;
- (BOOL)resume;
- (BOOL)flush;

- (BOOL)setAudioCurrentTime:(CMTime)time;
- (BOOL)setVideoCurrentTime:(CMTime)time;
- (BOOL)markAsAudioStalled;

- (BOOL)preferredVideoTime:(CMTime *)time advanced:(CMTime *)advanced;

@end

@protocol SGClockDelegate <NSObject>

- (void)clock:(SGClock *)clock didChcnageCurrentTime:(CMTime)currentTime;

@end
