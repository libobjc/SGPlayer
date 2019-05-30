//
//  SGAudioSelection.h
//  SGPlayer iOS
//
//  Created by Single on 2019/5/30.
//  Copyright © 2019 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAudioDescription.h"
#import "SGTrack.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *
 */
typedef NS_OPTIONS(NSUInteger, SGAudioSelectionActionFlags) {
    SGAudioSelectionAction_Tracks = 1 << 0,
    SGAudioSelectionAction_Weights = 1 << 1,
    SGAudioSelectionAction_AudioDescription = 1 << 2,
};

@interface SGAudioSelection : NSObject <NSCopying>

/**
 *
 */
@property (nonatomic, copy) NSArray<SGTrack *> *tracks;

/**
 *
 */
@property (nonatomic, copy) NSArray<NSNumber *> *weights;

/**
 *
 */
@property (nonatomic, copy) SGAudioDescription *audioDescription;

@end

NS_ASSUME_NONNULL_END
