//
//  SGAudioProcessor.h
//  SGPlayer
//
//  Created by Single on 2018/11/28.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAudioSelection.h"
#import "SGAudioFrame.h"
#import "SGCapacity.h"

@interface SGAudioProcessor : NSObject

/**
 *
 */
@property (nonatomic, copy, readonly) SGAudioSelection *selection;

/**
 *
 */
- (void)setSelection:(SGAudioSelection *)selection actionFlags:(SGAudioSelectionActionFlags)actionFlags description:(SGAudioDescription *)description;

/**
 *
 */
- (SGAudioFrame *)putFrame:(SGAudioFrame *)frame;

/**
 *
 */
- (SGAudioFrame *)finish;

/**
 *
 */
- (SGCapacity)capacity;

/**
 *
 */
- (void)flush;

/**
 *
 */
- (void)close;

@end
