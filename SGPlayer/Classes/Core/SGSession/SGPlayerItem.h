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
@property (nonatomic, copy, readonly) NSError * _Nullable error;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<SGTrack *> * _Nullable tracks;

/**
 *
 */
@property (nonatomic, copy, readonly) NSDictionary * _Nullable metadata;

/**
 *
 */
@property (nonatomic, readonly) CMTime duration;

@end

@interface SGPlayerItem (AudioSelection)

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<SGTrack *> * _Nullable selectedAudioTracks;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<NSNumber *> * _Nullable selectedAudioWeights;

/**
 *
 */
- (BOOL)selectAudioTracks:(NSArray<SGTrack *> * _Nullable)tracks weights:(NSArray<NSNumber *> * _Nullable)weights;

@end

@interface SGPlayerItem (VideoSelection)

/**
 *
 */
@property (nonatomic, strong, readonly) SGTrack * _Nullable selectedVideoTrack;

/**
 *
 */
- (BOOL)selectVideoTrack:(SGTrack *)track;

@end

NS_ASSUME_NONNULL_END
