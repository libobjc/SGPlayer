//
//  SGPacket.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGObjectQueue.h"
#import "SGObjectPool.h"
#import "SGTrack.h"

@interface SGPacket : NSObject <SGObjectPoolItem, SGObjectQueueItem>

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
