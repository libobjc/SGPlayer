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

@protocol SGObjectQueueItem;
@protocol SGObjectQueueDelegate;

@interface SGObjectQueue : NSObject

/**
 *
 */
- (instancetype)initWithMaxCount:(uint64_t)maxCount;

/**
 *
 */
@property (nonatomic, weak) id<SGObjectQueueDelegate> delegate;

/**
 *
 */
@property (nonatomic) BOOL shouldSortObjects;

/**
 *
 */
- (SGCapacity *)capacity;

/**
 *
 */
- (SGBlock)putObjectSync:(id<SGObjectQueueItem>)object;
- (SGBlock)putObjectSync:(id<SGObjectQueueItem>)object before:(SGBlock)before after:(SGBlock)after;

/**
 *
 */
- (SGBlock)putObjectAsync:(id<SGObjectQueueItem>)object;

/**
 *
 */
- (SGBlock)getObjectSync:(id<SGObjectQueueItem> *)object;
- (SGBlock)getObjectSync:(id<SGObjectQueueItem> *)object before:(SGBlock)before after:(SGBlock)after;
- (SGBlock)getObjectSync:(id<SGObjectQueueItem> *)object before:(SGBlock)before after:(SGBlock)after timeReader:(SGTimeReader)timeReader;

/**
 *
 */
- (SGBlock)getObjectAsync:(id<SGObjectQueueItem> *)object;
- (SGBlock)getObjectAsync:(id<SGObjectQueueItem> *)object timeReader:(SGTimeReader)timeReader;

/**
 *
 */
- (SGBlock)flush;

/**
 *
 */
- (SGBlock)destroy;

@end

@protocol SGObjectQueueDelegate <NSObject>

/**
 *
 */
- (void)objectQueue:(SGObjectQueue *)objectQueue didChangeCapacity:(SGCapacity *)capacity;

@end

@protocol SGObjectQueueItem <NSObject>

/**
 *
 */
- (void)lock;

/**
 *
 */
- (void)unlock;

/**
 *
 */
- (int)size;

/**
 *
 */
- (CMTime)duration;

/**
 *
 */
- (CMTime)timeStamp;

@end
