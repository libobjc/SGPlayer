//
//  SGAudioSelection.h
//  SGPlayer iOS
//
//  Created by Single on 2019/5/30.
//  Copyright © 2019 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAudioDescriptor.h"
#import "SGTrack.h"

/**
 *
 */
typedef NS_OPTIONS(NSUInteger, SGAudioSelectionActionFlags) {
    SGAudioSelectionActionTracks  = 1 << 0,
    SGAudioSelectionActionWeights = 1 << 1,
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

@end
