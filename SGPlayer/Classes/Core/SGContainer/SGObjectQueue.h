//
//  SGObjectQueue.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTime.h"

@protocol SGObjectQueueItem <NSObject, NSLocking>

- (CMTime)offset;
- (CMTime)scale;
- (CMTime)timeStamp;
- (CMTime)duration;
- (CMTime)originalTimeStamp;
- (CMTime)originalDuration;
- (long long)size;

@end

@interface SGObjectQueue : NSObject

- (instancetype)init;
- (instancetype)initWithMaxCount:(NSInteger)maxCount;

@property (nonatomic, assign) BOOL shouldSortObjects;

- (CMTime)duration;
- (long long)size;
- (NSUInteger)count;

- (void)putObjectSync:(__kindof id <SGObjectQueueItem>)object;
- (void)putObjectAsync:(__kindof id <SGObjectQueueItem>)object;

- (__kindof id <SGObjectQueueItem>)getObjectSync;
- (__kindof id <SGObjectQueueItem>)getObjectAsync;

- (__kindof id <SGObjectQueueItem>)getObjectSyncWithPTSHandler:(BOOL(^)(CMTime * current, CMTime * expect))ptsHandler drop:(BOOL)drop;
- (__kindof id <SGObjectQueueItem>)getObjectAsyncWithPTSHandler:(BOOL(^)(CMTime * current, CMTime * expect))ptsHandler drop:(BOOL)drop;

- (void)flush;
- (void)destroy;

@end
