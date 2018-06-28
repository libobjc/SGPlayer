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

@property (nonatomic, copy, readonly) NSError * error;
@property (nonatomic, weak) id <SGFFAudioPlayerDelegate> delegate;

/**
 *  Volume.
 */
@property (nonatomic, assign, readonly) float volume;
- (BOOL)setVolume:(float)volume error:(NSError **)error;

/**
 *  Rate.
 */
@property (nonatomic, assign, readonly) float rate;
- (BOOL)setRate:(float)rate error:(NSError **)error;

/**
 *  Audio Stream Basic Description.
 */
@property (nonatomic, assign, readonly) AudioStreamBasicDescription asbd;
- (BOOL)setAsbd:(AudioStreamBasicDescription)asbd error:(NSError **)error;

/**
 *  Playback.
 */
@property (nonatomic, assign, readonly) BOOL playing;

- (void)play;
- (void)pause;

@end
