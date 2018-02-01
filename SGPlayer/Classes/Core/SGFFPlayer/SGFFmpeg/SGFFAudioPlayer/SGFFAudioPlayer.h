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

- (void)audioPlayerShouldInputData:(SGFFAudioPlayer *)audioPlayer ioData:(AudioBufferList *)ioData numberOfSamples:(UInt32)numberOfSamples numberOfChannels:(UInt32)numberOfChannels;
@optional
- (void)audioPlayerWillRenderSample:(SGFFAudioPlayer *)audioPlayer sampleTimestamp:(const AudioTimeStamp * )sampleTimestamp;
- (void)audioPlayerDidRenderSample:(SGFFAudioPlayer *)audioPlayer sampleTimestamp:(const AudioTimeStamp * )sampleTimestamp;

@end

@interface SGFFAudioPlayer : NSObject

- (instancetype)initWithDelegate:(id <SGFFAudioPlayerDelegate>)delegate;

@property (nonatomic, assign) float volume;

- (int)sampleRate;
- (int)numberOfChannels;
- (BOOL)running;

- (void)play;
- (void)pause;

@end
