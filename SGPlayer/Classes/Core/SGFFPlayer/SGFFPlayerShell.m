//
//  SGFFPlayerShell.m
//  SGPlayer
//
//  Created by Single on 2017/11/2.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFFPlayerShell.h"

@implementation SGFFPlayerShell

+ (instancetype)playerWithAbstractPlayer:(SGPlayer *)abstractPlayer {return nil;}

- (void)replaceVideo {}
- (void)reloadVolume {}
- (void)reloadPlayableBufferInterval {}

- (void)play {}
- (void)pause {}
- (void)stop {}

- (void)seekToTime:(NSTimeInterval)time {}
- (void)seekToTime:(NSTimeInterval)time completeHandler:(void(^)(BOOL finished))completeHandler {}

- (void)selectAudioTrackIndex:(int)audioTrackIndex {}

@end
