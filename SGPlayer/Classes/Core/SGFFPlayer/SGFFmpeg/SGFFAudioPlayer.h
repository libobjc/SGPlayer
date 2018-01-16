//
//  SGFFAudioPlayer.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGFFAudioPlayer : NSObject

@property (nonatomic, assign, readonly) Float64 samplingRate;
@property (nonatomic, assign, readonly) UInt32 numberOfChannels;

- (void)play;
- (void)pause;

- (BOOL)registerAudioSession;
- (void)unregisterAudioSession;

@end
