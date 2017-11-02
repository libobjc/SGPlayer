//
//  SGFFPlayerShell.h
//  SGPlayer
//
//  Created by Single on 2017/11/2.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPlayerImp.h"

@interface SGFFPlayerShell : NSObject

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)init NS_UNAVAILABLE;

+ (instancetype)playerWithAbstractPlayer:(SGPlayer *)abstractPlayer;

@property (nonatomic, weak, readonly) SGPlayer * abstractPlayer;

@property (nonatomic, assign, readonly) SGPlayerState state;
@property (nonatomic, assign, readonly) CGSize presentationSize;
@property (nonatomic, assign, readonly) NSTimeInterval bitrate;
@property (nonatomic, assign, readonly) NSTimeInterval progress;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval playableTime;
@property (nonatomic, assign, readonly) BOOL seeking;

- (void)replaceVideo;
- (void)reloadVolume;
- (void)reloadPlayableBufferInterval;

- (void)play;
- (void)pause;
- (void)stop;

@property (nonatomic, assign, readonly) BOOL seekEnable;
- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time completeHandler:(void(^)(BOOL finished))completeHandler;

@property (nonatomic, assign, readonly) BOOL videoDecodeOnMainThread;


#pragma mark - track info

@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, assign, readonly) BOOL audioEnable;

@property (nonatomic, strong, readonly) SGPlayerTrack * videoTrack;
@property (nonatomic, strong, readonly) SGPlayerTrack * audioTrack;

@property (nonatomic, strong, readonly) NSArray <SGPlayerTrack *> * videoTracks;
@property (nonatomic, strong, readonly) NSArray <SGPlayerTrack *> * audioTracks;

- (void)selectAudioTrackIndex:(int)audioTrackIndex;

@end
