//
//  SGVideoPlaybackOutput.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGOutput.h"
#import "SGPlatform.h"
#import "SGPlaybackTimeSync.h"

@interface SGVideoPlaybackOutput : NSObject <SGOutput>

@property (nonatomic, strong) SGPlaybackTimeSync * timeSync;
@property (nonatomic, assign) CMTime rate;
@property (nonatomic, strong) SGPLFView * view;

@end
