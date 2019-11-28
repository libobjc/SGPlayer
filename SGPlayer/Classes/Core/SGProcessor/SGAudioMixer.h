//
//  SGAudioMixer.h
//  SGPlayer
//
//  Created by Single on 2018/11/29.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAudioDescriptor.h"
#import "SGAudioFrame.h"
#import "SGCapacity.h"

@interface SGAudioMixer : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithTracks:(NSArray<SGTrack *> *)tracks weights:(NSArray<NSNumber *> *)weights;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<SGTrack *> *tracks;

/**
 *
 */
@property (nonatomic, copy) NSArray<NSNumber *> *weights;

/**
 *
 */
- (SGAudioFrame *)putFrame:(SGAudioFrame *)frame;

/**
 *
 */
- (SGAudioFrame *)finish;

/**
 *
 */
- (SGCapacity)capacity;

/**
 *
 */
- (void)flush;

@end
