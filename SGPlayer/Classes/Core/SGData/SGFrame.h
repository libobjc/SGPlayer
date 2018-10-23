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
#import "SGDefines.h"
#import "SGStream.h"

@interface SGFrame : NSObject <SGObjectPoolItem, SGObjectQueueItem>

@property (nonatomic, assign, readonly) void * coreptr;

//@property (nonatomic, strong, readonly) SGStream * stream;
//@property (nonatomic, assign, readonly) CMTime timeStamp;
//@property (nonatomic, assign, readonly) CMTime decodeTimeStamp;
//@property (nonatomic, assign, readonly) CMTime duration;
//@property (nonatomic, assign, readonly) long long size;

@property (nonatomic, strong) SGStream * stream;
@property (nonatomic, assign) CMTime timeStamp;
@property (nonatomic, assign) CMTime decodeTimeStamp;
@property (nonatomic, assign) CMTime duration;
@property (nonatomic, assign) long long size;

@end
