//
//  SGFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGObjectQueue.h"
#import "SGObjectPool.h"
#import "SGTrack.h"

static int const SGFramePlaneCount = 8;

@interface SGFrame : NSObject <SGObjectPoolItem, SGObjectQueueItem>

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
