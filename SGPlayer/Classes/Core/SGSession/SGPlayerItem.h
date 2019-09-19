//
//  SGPlayerItem.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTrackSelection.h"
#import "SGAsset.h"
#import "SGTrack.h"

@interface SGPlayerItem : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method initWithAsset:
 @abstract
    Initializes an SGPlayerItem with asset.
 */
- (instancetype)initWithAsset:(SGAsset *)asset;

/*!
 @property error
 @abstract
    If the loading item failed, this describes the error that caused the failure.
 */
@property (nonatomic, copy, readonly) NSError *error;

/*!
 @property tracks
 @abstract
    Provides array of SGPlayerItem tracks.
 */
@property (nonatomic, copy, readonly) NSArray<SGTrack *> *tracks;

/*!
 @property duration
 @abstract
    Indicates the metadata of the item.
 */
@property (nonatomic, copy, readonly) NSDictionary *metadata;

/*!
 @property duration
 @abstract
    Indicates the duration of the item.
 */
@property (nonatomic, readonly) CMTime duration;

/*!
 @property duration
 @abstract
    Indicates the audioSelection of the item.
 */
@property (nonatomic, copy, readonly) SGTrackSelection *audioSelection;

/*!
 @method setAudioSelection:action:
 @abstract
    Select specific audio tracks.
 */
- (void)setAudioSelection:(SGTrackSelection *)audioSelection action:(SGTrackSelectionAction)action;

/*!
 @property duration
 @abstract
    Indicates the videoSelection of the item.
 */
@property (nonatomic, copy, readonly) SGTrackSelection *videoSelection;

/*!
 @method setVideoSelection:action:
 @abstract
    Select specific video tracks.
 */
- (void)setVideoSelection:(SGTrackSelection *)videoSelection action:(SGTrackSelectionAction)action;

@end
