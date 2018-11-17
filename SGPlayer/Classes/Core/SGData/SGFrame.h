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

static int const SGFramePlaneCount = 8;

@interface SGFrame : NSObject <SGObjectPoolItem, SGObjectQueueItem>

@property (nonatomic, readonly) void * coreptr;

@property (nonatomic, readonly) SGMediaType type;
@property (nonatomic, readonly) uint64_t size;
@property (nonatomic, readonly) CMTime duration;
@property (nonatomic, readonly) CMTime timeStamp;
@property (nonatomic, readonly) CMTime decodeTimeStamp;

@end
