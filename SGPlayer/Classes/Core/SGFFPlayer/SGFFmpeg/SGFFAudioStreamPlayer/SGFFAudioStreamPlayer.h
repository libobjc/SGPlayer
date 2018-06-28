//
//  SGFFAudioStreamPlayer.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class SGFFAudioStreamPlayer;

@protocol SGFFAudioStreamPlayerDelegate <NSObject>

- (void)audioPlayer:(SGFFAudioStreamPlayer *)audioPlayer inputSample:(const AudioTimeStamp *)timestamp ioData:(AudioBufferList *)ioData numberOfSamples:(UInt32)numberOfSamples;

@optional
- (void)audioStreamPlayer:(SGFFAudioStreamPlayer *)audioDataPlayer prepareSample:(const AudioTimeStamp *)timestamp;
- (void)audioStreamPlayer:(SGFFAudioStreamPlayer *)audioDataPlayer postSample:(const AudioTimeStamp *)timestamp;
- (void)audioStreamPlayerDidFailed:(SGFFAudioStreamPlayer *)audioDataPlayer;

@end

@interface SGFFAudioStreamPlayer : NSObject

@property (nonatomic, copy, readonly) NSError * error;
@property (nonatomic, weak) id <SGFFAudioStreamPlayerDelegate> delegate;

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
