//
//  SGObjectQueue.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGCapacity.h"
#import "SGDefines.h"
#import "SGTime.h"

@protocol SGObjectQueueItem <NSObject>

- (CMTime)timeStamp;
- (CMTime)duration;
- (uint64_t)size;
- (void)lock;
- (void)unlock;

@end

@class SGObjectQueue;

@protocol SGObjectQueueDelegate <NSObject>

- (void)objectQueue:(SGObjectQueue *)objectQueue didChangeCapacity:(SGCapacity *)capacity;

@end

@interface SGObjectQueue : NSObject

- (instancetype)init;
- (instancetype)initWithMaxCount:(uint64_t)maxCount;

@property (nonatomic, weak) id <SGObjectQueueDelegate> delegate;
@property (nonatomic) BOOL shouldSortObjects;

- (SGCapacity *)capacity;

#pragma mark - Put Sync

- (SGBlock)putObjectSync:(id <SGObjectQueueItem>)object;
- (SGBlock)putObjectSync:(id <SGObjectQueueItem>)object before:(SGBlock)before after:(SGBlock)after;

#pragma mark - Put Async

- (SGBlock)putObjectAsync:(id <SGObjectQueueItem>)object;

#pragma mark - Get Sync

- (SGBlock)getObjectSync:(id <SGObjectQueueItem> *)object;
- (SGBlock)getObjectSync:(id <SGObjectQueueItem> *)object before:(SGBlock)before after:(SGBlock)after;
- (SGBlock)getObjectSync:(id <SGObjectQueueItem> *)object before:(SGBlock)before after:(SGBlock)after timeReader:(SGTimeReaderBlock)timeReader;

#pragma mark - Get Async

- (SGBlock)getObjectAsync:(id <SGObjectQueueItem> *)object;
- (SGBlock)getObjectAsync:(id <SGObjectQueueItem> *)object timeReader:(SGTimeReaderBlock)timeReader;

#pragma mark - Common

- (SGBlock)flush;
- (SGBlock)destroy;

@end
