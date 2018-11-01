//
//  SGAudioStreamPlayer.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class SGAudioStreamPlayer;

@protocol SGAudioStreamPlayerDelegate <NSObject>

@optional
- (void)audioStreamPlayer:(SGAudioStreamPlayer *)player preRender:(const AudioTimeStamp *)timestamp;
- (void)audioStreamPlayer:(SGAudioStreamPlayer *)player render:(const AudioTimeStamp *)timeStamp data:(AudioBufferList *)data nb_samples:(uint32_t)nb_samples;
- (void)audioStreamPlayer:(SGAudioStreamPlayer *)player postRender:(const AudioTimeStamp *)timestamp;

@end

@interface SGAudioStreamPlayer : NSObject

@property (nonatomic, copy, readonly) NSError * error;
@property (nonatomic, weak) id <SGAudioStreamPlayerDelegate> delegate;

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
