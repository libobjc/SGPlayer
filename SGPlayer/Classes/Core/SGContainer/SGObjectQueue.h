//
//  SGObjectQueue.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGCapacity.h"
#import "SGMacro.h"
#import "SGTime.h"

@protocol SGObjectQueueItem <NSObject, NSLocking>

- (CMTime)timeStamp;
- (CMTime)duration;
- (uint64_t)size;

@end

@class SGObjectQueue;

@protocol SGObjectQueueDelegate <NSObject>

- (void)objectQueue:(SGObjectQueue *)objectQueue didChangeCapacity:(SGCapacity *)capacity;

@end

@interface SGObjectQueue : NSObject

- (instancetype)init;
- (instancetype)initWithMaxCount:(NSUInteger)maxCount;

@property (nonatomic, weak) id <SGObjectQueueDelegate> delegate;
@property (nonatomic, assign) BOOL shouldSortObjects;

- (SGCapacity *)capacity;

#pragma mark - Put Sync

- (SGBasicBlock)putObjectSync:(__kindof id <SGObjectQueueItem>)object;
- (SGBasicBlock)putObjectSync:(__kindof id <SGObjectQueueItem>)object waitHandler:(void (^)(void))waitHandler resumeHandler:(void (^)(void))resumeHandler;

#pragma mark - Put Async

- (SGBasicBlock)putObjectAsync:(__kindof id <SGObjectQueueItem>)object;

#pragma mark - Get Sync

- (SGBasicBlock)getObjectSync:(__kindof id <SGObjectQueueItem> *)object;
- (SGBasicBlock)getObjectSync:(__kindof id <SGObjectQueueItem> *)object waitHandler:(void (^)(void))waitHandler resumeHandler:(void (^)(void))resumeHandler;
- (SGBasicBlock)getObjectSync:(__kindof id <SGObjectQueueItem> *)object waitHandler:(void (^)(void))waitHandler resumeHandler:(void (^)(void))resumeHandler ptsHandler:(BOOL(^)(CMTime * current, CMTime * expect))ptsHandler drop:(BOOL)drop;

#pragma mark - Get Async

- (SGBasicBlock)getObjectAsync:(__kindof id <SGObjectQueueItem> *)object;
- (SGBasicBlock)getObjectAsync:(__kindof id <SGObjectQueueItem> *)object ptsHandler:(BOOL(^)(CMTime * current, CMTime * expect))ptsHandler drop:(BOOL)drop;

#pragma mark - Common

- (SGBasicBlock)flush;
- (SGBasicBlock)destroy;

@end
