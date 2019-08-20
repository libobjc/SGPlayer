//
//  SGProcessor.h
//  SGPlayer
//
//  Created by Single on 2019/8/13.
//  Copyright © 2019 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTrackSelection.h"
#import "SGCapacity.h"
#import "SGFrame.h"

@protocol SGProcessor <NSObject>

/**
 *
 */
- (void)setSelection:(SGTrackSelection *)selection action:(SGTrackSelectionAction)action;

/**
 *
 */
- (__kindof SGFrame *)putFrame:(__kindof SGFrame *)frame;

/**
 *
 */
- (__kindof SGFrame *)finish;

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
