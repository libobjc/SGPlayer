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
#import "SGData.h"
#import "SGTime.h"

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
- (SGBlock)putObjectSync:(id<SGData>)object;
- (SGBlock)putObjectSync:(id<SGData>)object before:(SGBlock)before after:(SGBlock)after;

/**
 *
 */
- (SGBlock)putObjectAsync:(id<SGData>)object;

/**
 *
 */
- (SGBlock)getObjectSync:(id<SGData> *)object;
- (SGBlock)getObjectSync:(id<SGData> *)object before:(SGBlock)before after:(SGBlock)after;
- (SGBlock)getObjectSync:(id<SGData> *)object before:(SGBlock)before after:(SGBlock)after timeReader:(SGTimeReader)timeReader;

/**
 *
 */
- (SGBlock)getObjectAsync:(id<SGData> *)object;
- (SGBlock)getObjectAsync:(id<SGData> *)object timeReader:(SGTimeReader)timeReader;

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
