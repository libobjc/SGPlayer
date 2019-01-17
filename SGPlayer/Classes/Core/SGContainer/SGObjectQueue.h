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

NS_ASSUME_NONNULL_BEGIN

@interface SGObjectQueue : NSObject

/**
 *
 */
- (instancetype)initWithMaxCount:(uint64_t)maxCount;

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
- (BOOL)putObjectSync:(id<SGData>)object;
- (BOOL)putObjectSync:(id<SGData>)object before:(SGBlock _Nullable)before after:(SGBlock _Nullable)after;

/**
 *
 */
- (BOOL)putObjectAsync:(id<SGData>)object;

/**
 *
 */
- (BOOL)getObjectSync:(id<SGData> _Nullable * _Nonnull)object;
- (BOOL)getObjectSync:(id<SGData> _Nullable * _Nonnull)object before:(SGBlock _Nullable)before after:(SGBlock _Nullable)after;

/**
 *
 */
- (BOOL)getObjectAsync:(id<SGData> _Nullable * _Nonnull)object;
- (BOOL)getObjectAsync:(id<SGData> _Nullable * _Nonnull)object timeReader:(SGTimeReader _Nullable)timeReader;

/**
 *
 */
- (BOOL)flush;

/**
 *
 */
- (BOOL)destroy;

@end

NS_ASSUME_NONNULL_END
