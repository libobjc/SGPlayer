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

@interface SGAsyncDecodable : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithDecodableClass:(Class _Nonnull)decodableClass NS_DESIGNATED_INITIALIZER;

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

/**
 *
 */
- (void)decoder:(SGAsyncDecodable * _Nonnull)decoder didFinish:(int)index;

@end
