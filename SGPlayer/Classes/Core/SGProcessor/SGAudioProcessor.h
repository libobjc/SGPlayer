//
//  SGAudioProcessor.h
//  SGPlayer
//
//  Created by Single on 2018/11/28.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAudioDescription.h"
#import "SGAudioFrame.h"
#import "SGCapacity.h"

@interface SGAudioProcessor : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithAudioDescription:(SGAudioDescription * _Nullable)audioDescription NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic, copy, readonly) SGAudioDescription * _Nonnull audioDescription;

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
- (SGAudioFrame * _Nullable)putFrame:(SGAudioFrame * _Nonnull)frame;

/**
 *
 */
- (SGAudioFrame * _Nullable)finish;

/**
 *
 */
- (SGCapacity * _Nonnull)capacity;

/**
 *
 */
- (void)flush;

/**
 *
 */
- (void)close;

@end
