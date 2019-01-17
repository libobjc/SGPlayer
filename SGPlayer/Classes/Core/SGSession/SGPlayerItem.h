//
//  SGPlayerItem.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAsset.h"
#import "SGTrack.h"

NS_ASSUME_NONNULL_BEGIN

@interface SGPlayerItem : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithAsset:(SGAsset *)asset NS_DESIGNATED_INITIALIZER;

/**
 *
 */
- (NSError * _Nullable)error;

/**
 *
 */
- (CMTime)duration;

/**
 *
 */
- (NSDictionary * _Nullable)metadata;

/**
 *
 */
- (NSArray<SGTrack *> * _Nullable)tracks;

/**
 *
 */
- (NSArray<SGTrack *> * _Nullable)selectedAudioTracks;

/**
 *
 */
- (NSArray<NSNumber *> * _Nullable)selectedAudioWeights;

/**
 *
 */
- (BOOL)selectAudioTracks:(NSArray<SGTrack *> * _Nullable)tracks
                  weights:(NSArray<NSNumber *> * _Nullable)weights;

/**
 *
 */
- (SGTrack * _Nullable)selectedVideoTrack;

/**
 *
 */
- (BOOL)selectVideoTrack:(SGTrack *)track;

@end

NS_ASSUME_NONNULL_END
