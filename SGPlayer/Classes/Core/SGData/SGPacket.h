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

@property (nonatomic, readonly) void * core_ptr;
@property (nonatomic, readonly) void * codecpar_ptr;

@property (nonatomic, readonly) SGMediaType type;
@property (nonatomic, readonly) int32_t index;

@property (nonatomic, readonly) CMTime timeStamp;
@property (nonatomic, readonly) CMTime decodeTimeStamp;
@property (nonatomic, readonly) CMTime duration;
@property (nonatomic, readonly) uint64_t size;

@end
