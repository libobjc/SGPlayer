//
//  SGPlayerItem.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAudioSelection.h"
#import "SGVideoSelection.h"
#import "SGAsset.h"
#import "SGTrack.h"

@interface SGPlayerItem : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithAsset:(SGAsset *)asset;

/**
 *
 */
@property (nonatomic, copy, readonly) NSError *error;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<SGTrack *> *tracks;

/**
 *
 */
@property (nonatomic, copy, readonly) NSDictionary *metadata;

/**
 *
 */
@property (nonatomic, readonly) CMTime duration;

/**
 *
 */
@property (nonatomic, copy, readonly) SGAudioSelection *audioSelection;

/**
 *
 */
- (void)setAudioSelection:(SGAudioSelection *)audioSelection actionFlags:(SGAudioSelectionActionFlags)actionFlags;

/**
 *
 */
@property (nonatomic, copy, readonly) SGVideoSelection *videoSelection;

/**
 *
 */
- (void)setVideoSelection:(SGVideoSelection *)videoSelection actionFlags:(SGVideoSelectionActionFlags)actionFlags;

@end
