//
//  SGFFAudioOutput.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFOutput.h"

@interface SGFFAudioOutput : NSObject <SGFFOutput>

@property (nonatomic, copy, readonly) NSError * error;

@property (nonatomic, assign) float volume;
@property (nonatomic, assign) CMTime rate;

- (void)play;
- (void)pause;

@end
