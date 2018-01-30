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

- (void)audioPlayer:(SGFFAudioPlayer *)audioPlayer
             ioData:(AudioBufferList *)ioData
    numberOfSamples:(UInt32)numberOfSamples
   numberOfChannels:(UInt32)numberOfChannels;

@end

@interface SGFFAudioPlayer : NSObject

- (instancetype)initWithDelegate:(id <SGFFAudioPlayerDelegate>)delegate;

@property (nonatomic, assign) float volume;
@property (nonatomic, assign, readonly) int sampleRate;
@property (nonatomic, assign, readonly) int numberOfChannels;

- (void)play;
- (void)pause;

@end
