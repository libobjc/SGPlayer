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
typedef NS_ENUM(uint32_t, SGAsyncDecodableState) {
    SGAsyncDecodableStateNone,
    SGAsyncDecodableStateDecoding,
    SGAsyncDecodableStatePaused,
    SGAsyncDecodableStateClosed,
};

@interface SGAsyncDecodable : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithDecodable:(id<SGDecodable> _Nonnull)decodable NS_DESIGNATED_INITIALIZER;

/**
 *
 */
- (id<SGDecodable> _Nonnull)decodable;

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
- (SGCapacity * _Nonnull)capacity;

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
- (BOOL)finish;

/**
 *
 */
- (BOOL)putPacket:(SGPacket * _Nonnull)packet;

@end

@protocol SGAsyncDecodableDelegate <NSObject>

/**
 *
 */
- (void)decoder:(SGAsyncDecodable * _Nonnull)decoder didChangeState:(SGAsyncDecodableState)state;

/**
 *
 */
- (void)decoder:(SGAsyncDecodable * _Nonnull)decoder didChangeCapacity:(SGCapacity * _Nonnull)capacity;

/**
 *
 */
- (void)decoder:(SGAsyncDecodable * _Nonnull)decoder didOutputFrame:(__kindof SGFrame * _Nonnull)frame;

@end
