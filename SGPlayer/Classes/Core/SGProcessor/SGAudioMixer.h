//
//  SGAudioMixer.h
//  SGPlayer
//
//  Created by Single on 2018/11/29.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAudioDescription.h"
#import "SGAudioFrame.h"

@interface SGAudioMixer : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithAudioDescription:(SGAudioDescription * _Nullable)audioDescription
                                  tracks:(NSArray<SGTrack *> * _Nullable)tracks NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic, copy, readonly) SGAudioDescription * _Nonnull audioDescription;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<SGTrack *> * _Nullable tracks;

/**
 *
 */
@property (nonatomic, copy) NSArray<NSNumber *> * _Nullable weights;

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

@end
