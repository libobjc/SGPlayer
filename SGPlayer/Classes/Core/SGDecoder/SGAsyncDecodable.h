//
//  SGAsyncDecodable.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDecodable.h"
#import "SGCapacity.h"

@protocol SGAsyncDecodableDelegate;

/**
 *
 */
typedef NS_ENUM(int, SGAsyncDecodableState) {
    SGAsyncDecodableStateNone,
    SGAsyncDecodableStateDecoding,
    SGAsyncDecodableStateStalled,
    SGAsyncDecodableStatePaused,
    SGAsyncDecodableStateClosed,
};

NS_ASSUME_NONNULL_BEGIN

@interface SGAsyncDecodable : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithDecodableClass:(Class)decodableClass NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic, weak) id<SGAsyncDecodableDelegate> _Nullable delegate;

/**
 *
 */
- (SGAsyncDecodableState)state;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (BOOL)close;

/**
 *
 */
- (BOOL)pause;

/**
 *
 */
- (BOOL)resume;

/**
 *
 */
- (BOOL)flush;

/**
 *
 */
- (BOOL)finish:(NSArray<SGTrack *> *)tracks;

/**
 *
 */
- (BOOL)putPacket:(SGPacket *)packet;

@end

@protocol SGAsyncDecodableDelegate <NSObject>

/**
 *
 */
- (void)decoder:(SGAsyncDecodable *)decoder didChangeState:(SGAsyncDecodableState)state;

/**
 *
 */
- (void)decoder:(SGAsyncDecodable *)decoder didChangeCapacity:(SGCapacity *)capacity;

/**
 *
 */
- (void)decoder:(SGAsyncDecodable *)decoder didOutputFrame:(__kindof SGFrame *)frame;

@end

NS_ASSUME_NONNULL_END
