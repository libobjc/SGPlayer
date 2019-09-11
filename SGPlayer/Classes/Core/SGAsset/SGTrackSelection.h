//
//  SGTrackSelection.h
//  SGPlayer
//
//  Created by Single on 2019/8/13.
//  Copyright © 2019 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTrack.h"

typedef NS_OPTIONS(NSUInteger, SGTrackSelectionAction) {
    SGTrackSelectionActionTracks  = 1 << 0,
    SGTrackSelectionActionWeights = 1 << 1,
};

@interface SGTrackSelection : NSObject <NSCopying>

/*!
 @property tracks
 @abstract
    Provides array of SGTrackSelection tracks.
 */
@property (nonatomic, copy) NSArray<SGTrack *> *tracks;

/*!
 @property weights
 @abstract
    Provides array of SGTrackSelection weights.
 */
@property (nonatomic, copy) NSArray<NSNumber *> *weights;

@end
