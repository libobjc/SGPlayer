//
//  SGAudioPlayer.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class SGAudioPlayer;

@protocol SGAudioPlayerDelegate <NSObject>

/**
 *
 */
- (void)audioPlayer:(SGAudioPlayer *)player render:(const AudioTimeStamp *)timeStamp data:(AudioBufferList *)data numberOfFrames:(UInt32)numberOfFrames;

@optional
/**
 *
 */
- (void)audioPlayer:(SGAudioPlayer *)player willRender:(const AudioTimeStamp *)timestamp;

/**
 *
 */
- (void)audioPlayer:(SGAudioPlayer *)player didRender:(const AudioTimeStamp *)timestamp;

@end

@interface SGAudioPlayer : NSObject

/**
 *  Delegate.
 */
@property (nonatomic, weak) id<SGAudioPlayerDelegate> delegate;

/**
 *  Rate.
 */
@property (nonatomic) float rate;

/**
 *  Volume.
 */
@property (nonatomic) float volume;

/**
 *  ASBD.
 */
@property (nonatomic) AudioStreamBasicDescription asbd;

/**
 *  Playback.
 */
- (BOOL)isPlaying;

/**
 *  Play.
 */
- (void)play;

/**
 *  Pause.
 */
- (void)pause;

/**
 *  Flush.
 */
- (void)flush;

@end
