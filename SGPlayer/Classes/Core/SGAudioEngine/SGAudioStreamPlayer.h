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

NS_ASSUME_NONNULL_BEGIN

@protocol SGAudioStreamPlayerDelegate <NSObject>

@optional
- (void)audioStreamPlayer:(SGAudioStreamPlayer *)player preRender:(const AudioTimeStamp *)timestamp;
- (void)audioStreamPlayer:(SGAudioStreamPlayer *)player render:(const AudioTimeStamp *)timeStamp data:(AudioBufferList *)data nb_samples:(UInt32)nb_samples;
- (void)audioStreamPlayer:(SGAudioStreamPlayer *)player postRender:(const AudioTimeStamp *)timestamp;

@end

@interface SGAudioStreamPlayer : NSObject

@property (nonatomic, copy, readonly) NSError *error;
@property (nonatomic, weak) id<SGAudioStreamPlayerDelegate> delegate;

/**
 *  Volume.
 */
@property (nonatomic, readonly) float volume;
- (BOOL)setVolume:(float)volume error:(NSError **)error;

/**
 *  Rate.
 */
@property (nonatomic, readonly) float rate;
- (BOOL)setRate:(float)rate error:(NSError **)error;

/**
 *  Audio Stream Basic Description.
 */
@property (nonatomic, readonly) AudioStreamBasicDescription asbd;
- (BOOL)setAsbd:(AudioStreamBasicDescription)asbd error:(NSError **)error;

/**
 *  Playback.
 */
@property (nonatomic, readonly) BOOL playing;

- (void)play;
- (void)pause;
- (void)flush;

@end

NS_ASSUME_NONNULL_END
