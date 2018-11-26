//
//  SGAsyncDecoder.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDecodable.h"
#import "SGCapacity.h"

@protocol SGAsyncDecoderDelegate;

/**
 *
 */
typedef NS_ENUM(uint32_t, SGAsyncDecoderState) {
    SGAsyncDecoderStateNone,
    SGAsyncDecoderStateDecoding,
    SGAsyncDecoderStatePaused,
    SGAsyncDecoderStateClosed,
};

@interface SGAsyncDecoder : NSObject

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
@property (nonatomic, weak) id<SGAsyncDecoderDelegate> _Nullable delegate;

/**
 *
 */
- (SGAsyncDecoderState)state;

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

@protocol SGAsyncDecoderDelegate <NSObject>

/**
 *
 */
- (void)decoder:(SGAsyncDecoder * _Nonnull)decoder didChangeState:(SGAsyncDecoderState)state;

/**
 *
 */
- (void)decoder:(SGAsyncDecoder * _Nonnull)decoder didChangeCapacity:(SGCapacity * _Nonnull)capacity;

/**
 *
 */
- (void)decoder:(SGAsyncDecoder * _Nonnull)decoder didOutputFrame:(__kindof SGFrame * _Nonnull)frame;

@end
