//
//  SGAudioMixer.h
//  SGPlayer
//
//  Created by Single on 2018/11/28.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAudioFrame.h"
#import "SGCapacity.h"

@interface SGAudioMixer : NSObject

/**
 *
 */
- (NSArray<SGTrack *> * _Nullable)tracks;

/**
 *
 */
- (NSArray<NSNumber *> * _Nullable)weights;

/**
 *
 */
- (BOOL)setTracks:(NSArray<SGTrack *> * _Nullable)tracks weights:(NSArray<NSNumber *> * _Nullable)weights;

/**
 *
 */
- (SGAudioFrame * _Nullable)mix:(SGAudioFrame * _Nonnull)frame;

/**
 *
 */
- (BOOL)isAvailable;

/**
 *
 */
- (SGCapacity *)capacity;

/**
 *
 */
- (void)finish;

/**
 *
 */
- (void)flush;

@end
