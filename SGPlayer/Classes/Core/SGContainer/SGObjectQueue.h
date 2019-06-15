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
- (SGCapacity)capacity;

/**
 *
 */
- (BOOL)putObjectSync:(id<SGData>)object;
- (BOOL)putObjectSync:(id<SGData>)object before:(SGBlock)before after:(SGBlock)after;

/**
 *
 */
- (BOOL)putObjectAsync:(id<SGData>)object;

/**
 *
 */
- (BOOL)getObjectSync:(id<SGData> *)object;
- (BOOL)getObjectSync:(id<SGData> *)object before:(SGBlock)before after:(SGBlock)after;

/**
 *
 */
- (BOOL)getObjectAsync:(id<SGData> *)object;
- (BOOL)getObjectAsync:(id<SGData> *)object timeReader:(SGTimeReader)timeReader discarded:(uint64_t *)discarded;

/**
 *
 */
- (BOOL)flush;

/**
 *
 */
- (BOOL)destroy;

@end
