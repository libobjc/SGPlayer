//
//  SGPlaybackAudioRenderer.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGRenderable.h"
#import "SGPlaybackClock.h"

@interface SGPlaybackAudioRenderer : NSObject <SGRenderable>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithClock:(SGPlaybackClock *)clock;

@property (nonatomic, assign) float volume;
@property (nonatomic, assign) CMTime rate;

@end
