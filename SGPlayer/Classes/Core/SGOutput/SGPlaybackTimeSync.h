//
//  SGPlaybackTimeSync.h
//  SGPlayer
//
//  Created by Single on 2018/6/14.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTime.h"

@class SGPlaybackTimeSync;

@protocol SGPlaybackTimeSyncDelegate <NSObject>

- (void)playbackTimeSyncDidChangeStartTime:(SGPlaybackTimeSync *)playbackTimeSync;

@end

@interface SGPlaybackTimeSync : NSObject

@property (nonatomic, weak) id <SGPlaybackTimeSyncDelegate> delegate;

@property (nonatomic, assign, readonly) CMTime time;
@property (nonatomic, assign, readonly) CMTime unlimitedTime;
@property (nonatomic, assign, readonly) CMTime keyTime;
@property (nonatomic, assign, readonly) CMTime startTime;

- (void)updateKeyTime:(CMTime)time duration:(CMTime)duration rate:(CMTime)rate;
- (void)flush;

@end
