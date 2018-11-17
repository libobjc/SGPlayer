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

@interface SGPacket : NSObject <SGObjectPoolItem, SGObjectQueueItem>

@property (nonatomic, readonly) void * coreptr;

@property (nonatomic, readonly) int32_t index;
@property (nonatomic, readonly) uint64_t size;
@property (nonatomic, readonly) CMTime duration;
@property (nonatomic, readonly) CMTime timeStamp;
@property (nonatomic, readonly) CMTime decodeTimeStamp;

@end
