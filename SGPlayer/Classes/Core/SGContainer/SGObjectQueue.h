//
//  SGObjectQueue.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGCapacity.h"
#import "SGTime.h"

@protocol SGObjectQueueItem <NSObject, NSLocking>

- (CMTime)timeStamp;
- (CMTime)duration;
- (uint64_t)size;

@end

@interface SGObjectQueue : NSObject

- (instancetype)init;
- (instancetype)initWithMaxCount:(NSUInteger)maxCount;

@property (nonatomic, assign) BOOL shouldSortObjects;

- (SGCapacity *)capacity;

- (void)putObjectSync:(__kindof id <SGObjectQueueItem>)object;
- (void)putObjectSync:(__kindof id <SGObjectQueueItem>)object waitHandler:(void (^)(void))waitHandler resumeHandler:(void (^)(void))resumeHandler;
- (void)putObjectAsync:(__kindof id <SGObjectQueueItem>)object;

- (__kindof id <SGObjectQueueItem>)getObjectSync;
- (__kindof id <SGObjectQueueItem>)getObjectSyncWithWaitHandler:(void (^)(void))waitHandler resumeHandler:(void (^)(void))resumeHandler;
- (__kindof id <SGObjectQueueItem>)getObjectSyncWithWaitHandler:(void (^)(void))waitHandler resumeHandler:(void (^)(void))resumeHandler ptsHandler:(BOOL(^)(CMTime * current, CMTime * expect))ptsHandler drop:(BOOL)drop;

- (__kindof id <SGObjectQueueItem>)getObjectAsync;
- (__kindof id <SGObjectQueueItem>)getObjectAsyncWithPTSHandler:(BOOL(^)(CMTime * current, CMTime * expect))ptsHandler drop:(BOOL)drop;

- (void)flush;
- (void)destroy;

@end
