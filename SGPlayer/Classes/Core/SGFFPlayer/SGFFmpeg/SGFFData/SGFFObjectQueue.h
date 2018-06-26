//
//  SGFFObjectQueue.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@protocol SGFFObjectQueueItem <NSObject, NSLocking>

- (CMTime)position;
- (CMTime)duration;
- (long long)size;

@end


@interface SGFFObjectQueue : NSObject

- (instancetype)init;
- (instancetype)initWithMaxCount:(NSInteger)maxCount;

@property (nonatomic, assign) BOOL shouldSortObjects;

- (NSInteger)count;
- (CMTime)duration;
- (long long)size;

- (void)putObjectSync:(__kindof id <SGFFObjectQueueItem>)object;
- (void)putObjectAsync:(__kindof id <SGFFObjectQueueItem>)object;

- (__kindof id <SGFFObjectQueueItem>)getObjectSync;
- (__kindof id <SGFFObjectQueueItem>)getObjectAsync;

- (__kindof id <SGFFObjectQueueItem>)getObjectSyncWithPositionHandler:(BOOL(^)(CMTime * current, CMTime * expect))positionHandler;
- (__kindof id <SGFFObjectQueueItem>)getObjectAsyncWithPositionHandler:(BOOL(^)(CMTime * current, CMTime * expect))positionHandler;

- (void)flush;
- (void)destroy;

@end
