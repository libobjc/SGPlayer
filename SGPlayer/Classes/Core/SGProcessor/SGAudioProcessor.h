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

NS_ASSUME_NONNULL_BEGIN

@interface SGAudioProcessor : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithAudioDescription:(SGAudioDescription *)audioDescription NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic, copy, readonly) SGAudioDescription *audioDescription;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<SGTrack *> * _Nullable tracks;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<NSNumber *> * _Nullable weights;

/**
 *
 */
- (BOOL)setTracks:(NSArray<SGTrack *> * _Nullable)tracks weights:(NSArray<NSNumber *> * _Nullable)weights;

/**
 *
 */
- (SGAudioFrame * _Nullable)putFrame:(SGAudioFrame *)frame;

/**
 *
 */
- (SGAudioFrame * _Nullable)finish;

/**
 *
 */
- (SGCapacity *)capacity;

/**
 *
 */
- (void)flush;

/**
 *
 */
- (void)close;

@end

NS_ASSUME_NONNULL_END
