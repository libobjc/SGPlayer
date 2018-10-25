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

@property (nonatomic, strong) SGPlaybackClock * timeSync;
@property (nonatomic, assign) CMTime rate;

@property (nonatomic, assign) float volume;
@property (nonatomic, assign) CMTime deviceDelay;

@end
