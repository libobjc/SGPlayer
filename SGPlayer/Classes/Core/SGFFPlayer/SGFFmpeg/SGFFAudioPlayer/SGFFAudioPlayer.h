//
//  SGFFAudioPlayer.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class SGFFAudioPlayer;

@protocol SGFFAudioPlayerDelegate <NSObject>

- (void)audioManager:(SGFFAudioPlayer *)audioManager outputData:(float *)outputData numberOfFrames:(UInt32)numberOfFrames numberOfChannels:(UInt32)numberOfChannels;

@end

@interface SGFFAudioPlayer : NSObject

+ (AudioStreamBasicDescription)defaultAudioStreamBasicDescription;

- (instancetype)initWithDelegate:(id <SGFFAudioPlayerDelegate>)delegate;

@property (nonatomic, assign) AudioStreamBasicDescription audioStreamBasicDescription;
@property (nonatomic, assign, readonly) int sampleRate;
@property (nonatomic, assign, readonly) int numberOfChannels;

- (void)play;
- (void)pause;

@end
