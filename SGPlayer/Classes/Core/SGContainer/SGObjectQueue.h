//
//  SGObjectQueue.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@protocol SGObjectQueueItem <NSObject, NSLocking>

- (CMTime)offset;
- (CMTime)scale;
- (CMTime)position;
- (CMTime)duration;
- (CMTime)pts;
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

- (__kindof id <SGObjectQueueItem>)getObjectSyncWithPositionHandler:(BOOL(^)(CMTime * current, CMTime * expect))positionHandler drop:(BOOL)drop;
- (__kindof id <SGObjectQueueItem>)getObjectAsyncWithPositionHandler:(BOOL(^)(CMTime * current, CMTime * expect))positionHandler drop:(BOOL)drop;

- (void)flush;
- (void)destroy;

@end
