//
//  SGPlaybackAudioOutput.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGOutput.h"
#import "SGPlaybackSynchronizer.h"

@interface SGPlaybackAudioOutput : NSObject <SGOutput>

@property (nonatomic, strong) SGPlaybackSynchronizer * timeSync;
@property (nonatomic, assign) CMTime rate;

@property (nonatomic, assign) float volume;
@property (nonatomic, assign) CMTime deviceDelay;

@end
