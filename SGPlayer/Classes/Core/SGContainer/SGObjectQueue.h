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

- (CMTime)scale;
- (CMTime)startTime;
- (CMTime)timeStamp;
- (CMTime)duration;
- (CMTime)originalTimeStamp;
- (CMTime)originalDuration;
- (int64_t)size;

@end

@interface SGObjectQueue : NSObject

- (instancetype)init;
- (instancetype)initWithMaxCount:(NSInteger)maxCount;

@property (nonatomic, assign) BOOL shouldSortObjects;

- (void)getDuratioin:(CMTime *)duration size:(int64_t *)size count:(NSUInteger *)count;

- (void)putObjectSync:(__kindof id <SGObjectQueueItem>)object;
- (void)putObjectAsync:(__kindof id <SGObjectQueueItem>)object;

- (__kindof id <SGObjectQueueItem>)getObjectSync;
- (__kindof id <SGObjectQueueItem>)getObjectAsync;

- (__kindof id <SGObjectQueueItem>)getObjectSyncWithPTSHandler:(BOOL(^)(CMTime * current, CMTime * expect))ptsHandler drop:(BOOL)drop;
- (__kindof id <SGObjectQueueItem>)getObjectAsyncWithPTSHandler:(BOOL(^)(CMTime * current, CMTime * expect))ptsHandler drop:(BOOL)drop;

- (void)flush;
- (void)destroy;

@end
