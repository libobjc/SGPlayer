//
//  SGAudioPlaybackOutput.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGOutput.h"

@interface SGAudioPlaybackOutput : NSObject <SGOutput>

@property (nonatomic, copy, readonly) NSError * error;

@property (nonatomic, strong) SGPlaybackTimeSync * timeSync;

@property (nonatomic, assign) float volume;
@property (nonatomic, assign) CMTime rate;

@end
