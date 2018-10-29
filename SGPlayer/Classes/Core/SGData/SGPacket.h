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

@property (nonatomic, assign, readonly) void * coreptr;

@property (nonatomic, strong, readonly) SGTrack * track;
@property (nonatomic, assign, readonly) CMTime timeStamp;
@property (nonatomic, assign, readonly) CMTime decodeTimeStamp;
@property (nonatomic, assign, readonly) CMTime duration;
@property (nonatomic, assign, readonly) uint64_t size;

@end
