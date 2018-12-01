//
//  SGFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTrack.h"
#import "SGData.h"

static int const SGFramePlaneCount = 8;

@interface SGFrame : NSObject <SGData>

/**
 *
 */
- (void * _Nonnull)coreptr;

/**
 *
 */
- (SGTrack * _Nullable)track;

/**
 *
 */
- (int)size;

/**
 *
 */
- (CMTime)duration;

/**
 *
 */
- (CMTime)timeStamp;

/**
 *
 */
- (CMTime)decodeTimeStamp;

@end
